{% from "orchestrate/aws_env_macro.jinja" import VPC_NAME, VPC_RESOURCE_SUFFIX,
 ENVIRONMENT, BUSINESS_UNIT, subnet_ids with context %}
load_elasticsearch_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/elasticsearch.conf
    - source: salt://orchestrate/aws/cloud_profiles/elasticsearch.conf
    - template: jinja

generate_elasticsearch_cloud_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/{{ VPC_RESOURCE_SUFFIX }}_elasticsearch_map.yml
    - source: salt://orchestrate/aws/map_templates/instance_map.yml
    - template: jinja
    - makedirs: True
    - context:
        service_name: elasticsearch
        environment_name: {{ ENVIRONMENT }}
        num_instances: 3
        roles:
          - elasticsearch
        securitygroupid:
          - {{ salt.boto_secgroup.get_group_id(
            'elasticsearch-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          - {{ salt.boto_secgroup.get_group_id(
            'salt_master-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          - {{ salt.boto_secgroup.get_group_id(
            'consul-agent-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
        subnetids: {{ subnet_ids }}
        volume_size: 200
        tags:
          escluster: edx-{{ ENVIRONMENT }}
          business_unit: {{ BUSINESS_UNIT }}
        profile_overrides:
          ebs_optimized: False
          size: t2.medium
          block_device_mappings:
            - DeviceName: xvda
              Ebs.VolumeSize: 20
              Ebs.VolumeType: gp2
            - DeviceName: /dev/xvdb
              Ebs.VolumeSize: 100
              Ebs.VolumeType: gp2
    - require:
        - file: load_elasticsearch_cloud_profile

deploy_elasticsearch_nodes:
  salt.runner:
    - name: cloud.map_run
    - path: /etc/salt/cloud.maps.d/{{ VPC_RESOURCE_SUFFIX }}_elasticsearch_map.yml
    - kwargs:
        parallel: True
    - require:
        - file: generate_elasticsearch_cloud_map_file

sync_external_modules_for_elasticsearch_nodes:
  salt.function:
    - name: saltutil.sync_all
    - tgt: 'G@roles:elasticsearch and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound

format_data_drive:
  salt.function:
    - tgt: 'G@roles:elasticsearch and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - name: state.single
    - arg:
        - blockdev.formatted
    - kwarg:
        name: /dev/xvdb
        fs_type: ext4
    - require:
        - salt: deploy_elasticsearch_nodes

mount_data_drive:
  salt.function:
    - tgt: 'G@roles:elasticsearch and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - name: state.single
    - arg:
        - mount.mounted
    - kwarg:
        name: /var/lib/elasticsearch
        device: /dev/xvdb
        fstype: ext4
        mkmnt: True
        opts: 'relatime,user'
    - require:
        - salt: format_data_drive

load_pillar_data_on_{{ ENVIRONMENT }}_elasticsearch_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:elasticsearch and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - require:
        - salt: deploy_elasticsearch_nodes

populate_mine_with_{{ ENVIRONMENT }}_elasticsearch_data:
  salt.function:
    - name: mine.update
    - tgt: 'G@roles:elasticsearch and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - require:
        - salt: load_pillar_data_on_{{ ENVIRONMENT }}_elasticsearch_nodes

{# Reload the pillar data to update values from the salt mine #}
reload_pillar_data_on_{{ ENVIRONMENT }}_elasticsearch_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:elasticsearch and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - require:
        - salt: populate_mine_with_{{ ENVIRONMENT }}_elasticsearch_data

install_git_on_elasticsearch_nodes_for_cloning_forked_python_packages:
  salt.function:
    - name: pkg.install
    - tgt: 'G@roles:elasticsearch and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - arg:
        - git

build_{{ ENVIRONMENT }}_elasticsearch_nodes:
  salt.state:
    - tgt: 'G@roles:elasticsearch and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - highstate: True
    - require:
        - salt: reload_pillar_data_on_{{ ENVIRONMENT }}_elasticsearch_nodes
