{% from "orchestrate/aws_env_macro.jinja" import VPC_NAME, VPC_RESOURCE_SUFFIX,
 ENVIRONMENT, subnet_ids with context %}
{% set mongo_admin_password = salt.vault.write('transit/random/42', format=base64)['data']['random_bytes'] %}

load_mongodb_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/mongodb.conf
    - source: salt://orchestrate/aws/cloud_profiles/mongodb.conf

generate_mongodb_cloud_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/{{ VPC_RESOURCE_SUFFIX }}_mongodb_map.yml
    - source: salt://orchestrate/aws/map_templates/mongodb.yml
    - template: jinja
    - makedirs: True
    - context:
        environment_name: {{ ENVIRONMENT }}
        roles:
          - mongodb
        securitygroupid:
          - {{ salt.boto_secgroup.get_group_id(
            'mongodb-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          - {{ salt.boto_secgroup.get_group_id(
            'salt_master-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          - {{ salt.boto_secgroup.get_group_id(
            'consul-agent-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          - {{ salt.boto_secgroup.get_group_id(
            'vault-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
        subnetids: {{ subnet_ids }}
    - require:
        - file: load_mongodb_cloud_profile

ensure_instance_profile_exists_for_mongodb:
  boto_iam_role.present:
    - name: mongodb-instance-role

deploy_mongodb_cloud_map:
  salt.function:
    - name: saltutil.runner
    - tgt: 'roles:master'
    - tgt_type: grain
    - arg:
        - cloud.map_run
    - kwarg:
        path: /etc/salt/cloud.maps.d/{{ VPC_RESOURCE_SUFFIX }}_mongodb_map.yml
        parallel: True
    - require:
        - file: generate_mongodb_cloud_map_file

format_data_drive:
  salt.function:
    - tgt: 'G@roles:mongodb and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - name: state.single
    - arg:
        - blockdev.formatted
    - kwarg:
        name: /dev/xvdb
        fs_type: ext4
    - require:
        - salt: deploy_mongodb_cloud_map

mount_data_drive:
  salt.function:
    - tgt: 'G@roles:mongodb and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - name: state.single
    - arg:
        - mount.mounted
    - kwarg:
        name: /var/lib/mongodb
        device: /dev/xvdb
        fstype: ext4
        mkmnt: True
        opts: 'relatime,user'
    - require:
        - salt: format_data_drive

load_pillar_data_on_mitx_mongodb_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:mongodb and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound

populate_mine_with_mongodb_node_data:
  salt.function:
    - name: mine.update
    - tgt: 'G@roles:mongodb and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - require:
        - salt: load_pillar_data_on_mitx_mongodb_nodes

build_mongodb_nodes:
  salt.state:
    - tgt: 'G@roles:mongodb and G@environment:{{ ENVIRONMENT }} and not G@roles:mongodb_primary'
    - tgt_type: compound
    - highstate: True
    - require:
        - salt: populate_mine_with_mongodb_node_data
    - pillar:
        mongodb:
          overrides:
            pkgs:
              - mongodb-org
              - python
              - python-pip

build_mongodb_master_node:
  salt.state:
    - tgt: 'G@roles:mongodb_primary and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - highstate: True
    - require:
        - salt: populate_mine_with_mongodb_node_data
    - pillar:
        mongodb:
          overrides:
            pkgs:
              - mongodb-org
              - python
              - python-pip
          admin_username: admin
          admin_password: {{ mongo_admin_password }}

configure_vault_mongodb_backend:
  vault.secret_backend_enabled:
    - backend_type: mongodb
    - description: Backend to create dynamic MongoDB credentials for {{ ENVIRONMENT }}
    - mount_point: mongodb-{{ ENVIRONMENT }}
    - lease_max: 4368h
    - lease: 4368h
    - connection_config:
        uri: "mongodb://admin:{{ mongo_admin_password }}@mongodb-master.service.{{ ENVIRONMENT }}.consul:27017/admin"
