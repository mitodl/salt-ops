{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT', 'rc-apps') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set VPC_NAME = env_data.vpc_name %}
{% set INSTANCE_COUNT = salt.environ.get('INSTANCE_COUNT', 3) %}
{% set BUSINESS_UNIT = salt.environ.get('BUSINESS_UNIT', env_data.business_unit) %}
{% set launch_date = salt.status.time(format="%Y-%m-%d") %}
{% set subnet_ids = salt.boto_vpc.describe_subnets(
    vpc_id=salt.boto_vpc.describe_vpcs(
        name=env_data.vpc_name).vpcs[0].id
    ).subnets|map(attribute='id')|list %}
{% set mongo_admin_password = salt.vault.read('secret-{}/{}/mongodb-admin-password'.format(BUSINESS_UNIT, ENVIRONMENT)) %}
{% if not mongo_admin_password %}
{% set mongo_admin_password = salt.random.get_str(42) %}
set_mongo_admin_password_in_vault:
  salt.function:
    - tgt: 'roles:master'
    - tgt_type: grain
    - name: vault.write
    - arg:
        - secret-{{ BUSINESS_UNIT }}/{{ ENVIRONMENT }}/mongodb-admin-password
    - kwarg:
        value: {{ mongo_admin_password }}
{% else %}
{% set mongo_admin_password = mongo_admin_password.data.value %}
{% endif %}
{% set SIX_MONTHS = '4368h' %}

load_mongodb_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/mongodb.conf
    - source: salt://orchestrate/aws/cloud_profiles/mongodb.conf
    - template: jinja

generate_mongodb_cloud_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/{{ ENVIRONMENT }}_mongodb_map.yml
    - source: salt://orchestrate/aws/map_templates/instance_map.yml
    - template: jinja
    - makedirs: True
    - context:
        service_name: mongodb
        environment_name: {{ ENVIRONMENT }}
        num_instances: 3
        tags:
          business_unit: {{ BUSINESS_UNIT }}
          Department: {{ BUSINESS_UNIT }}
          OU: {{ BUSINESS_UNIT }}
          Environment: {{ ENVIRONMENT }}
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
    - tgt: 'roles:master'
    - tgt_type: grain
    - name: saltutil.runner
    - arg:
        - cloud.map_run
    - kwarg:
        path: /etc/salt/cloud.maps.d/{{ ENVIRONMENT }}_mongodb_map.yml
        parallel: True
        full_return: True
    - require:
        - file: generate_mongodb_cloud_map_file

sync_external_modules_for_elasticsearch_nodes:
  salt.function:
    - name: saltutil.sync_all
    - tgt: 'G@roles:mongodb and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound

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

load_pillar_data_on_{{ ENVIRONMENT }}_mongodb_nodes:
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
        - salt: load_pillar_data_on_{{ ENVIRONMENT }}_mongodb_nodes

set_node_primary_node:
  salt.function:
    - tgt: 'mongodb-{{ ENVIRONMENT }}-0'
    - name: grains.append
    - arg:
        - roles
        - mongodb_primary
    - require:
        - salt: populate_mine_with_mongodb_node_data

build_mongodb_nodes:
  salt.state:
    - tgt: 'G@roles:mongodb and G@environment:{{ ENVIRONMENT }} and not G@roles:mongodb_primary'
    - tgt_type: compound
    - highstate: True
    - require:
        - salt: populate_mine_with_mongodb_node_data

build_mongodb_master_node:
  salt.state:
    - tgt: 'G@roles:mongodb_primary and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - highstate: True
    - require:
        - salt: populate_mine_with_mongodb_node_data
    - pillar:
        mongodb:
          admin_username: admin
          admin_password: {{ mongo_admin_password }}

unset_primary_node_grain:
  salt.function:
    - tgt: 'mongodb-{{ ENVIRONMENT }}-0'
    - name: grains.remove
    - arg:
        - roles
        - mongodb_primary
    - require:
        - salt: build_mongodb_master_node

configure_vault_mongodb_backend:
  vault.secret_backend_enabled:
    - backend_type: mongodb
    - description: Backend to create dynamic MongoDB credentials for {{ ENVIRONMENT }}
    - mount_point: mongodb-{{ ENVIRONMENT }}
    - ttl_max: {{ SIX_MONTHS }}
    - ttl_default: {{ SIX_MONTHS }}
    - lease_max: {{ SIX_MONTHS }}
    - lease_default: {{ SIX_MONTHS }}
    - connection_config:
        uri: "mongodb://admin:{{ mongo_admin_password }}@mongodb-master.service.{{ ENVIRONMENT }}.consul:27017/admin"
        verify_connection: False
