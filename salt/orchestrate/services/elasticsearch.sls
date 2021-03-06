{% set env_settings = salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml", dest=None)|load_yaml %}
{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT', 'rc-apps') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set purpose_data = env_data.purposes.elasticsearch|default({}) %}
{% set VPC_NAME = env_data.vpc_name %}
{% set INSTANCE_COUNT = salt.environ.get('INSTANCE_COUNT', purpose_data.get('num_instances', 3)) %}
{% set BUSINESS_UNIT = salt.environ.get('BUSINESS_UNIT', env_data.business_unit) %}
{% set launch_date = salt.status.time(format="%Y-%m-%d") %}
{% set subnet_ids = salt.boto_vpc.describe_subnets(
    vpc_id=salt.boto_vpc.describe_vpcs(
        name=env_data.vpc_name).vpcs[0].id
    ).subnets|rejectattr('availability_zone', 'equalto', 'us-east-1e')|map(attribute='id')|list %}
{% set app_name = 'elasticsearch' %}
{% set release_id = salt.sdb.get('sdb://consul/' ~ app_name ~ '/' ~ ENVIRONMENT ~ '/release-id')|default('v1') %}
{% set target_string = app_name ~ '-' ~ ENVIRONMENT ~ '-*-' ~ release_id %}

load_elasticsearch_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/elasticsearch.conf
    - source: salt://orchestrate/aws/cloud_profiles/elasticsearch.conf
    - template: jinja

generate_elasticsearch_cloud_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/{{ ENVIRONMENT }}_elasticsearch_map.yml
    - source: salt://orchestrate/aws/map_templates/instance_map.yml
    - template: jinja
    - makedirs: True
    - context:
        service_name: elasticsearch
        environment_name: {{ ENVIRONMENT }}
        num_instances: {{ INSTANCE_COUNT }}
        release_id: {{ release_id }}
        roles:
          - elasticsearch
        securitygroupid:
          - {{ salt.boto_secgroup.get_group_id(
            'elasticsearch-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          - {{ salt.boto_secgroup.get_group_id(
            'master-ssh-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          - {{ salt.boto_secgroup.get_group_id(
            'consul-agent-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
        subnetids: {{ subnet_ids|tojson }}
        tags:
          escluster: {{ ENVIRONMENT }}
          business_unit: {{ BUSINESS_UNIT }}
          Department: {{ BUSINESS_UNIT }}
          OU: {{ BUSINESS_UNIT }}
          Environment: {{ ENVIRONMENT }}
          launch-date: '{{ launch_date }}'
        profile_overrides:
          ebs_optimized: {{ purpose_data.ebs_optimized|default(True) }}
          size: {{ purpose_data.size|default('t3.medium') }}
          block_device_mappings:
            - DeviceName: xvda
              Ebs.VolumeSize: 20
              Ebs.VolumeType: gp2
            - DeviceName: /dev/xvdb
              Ebs.VolumeSize: {{ purpose_data.data_volume_size|default(100) }}
              Ebs.VolumeType: gp2
    - require:
        - file: load_elasticsearch_cloud_profile

deploy_elasticsearch_nodes:
  salt.runner:
    - name: cloud.map_run
    - path: /etc/salt/cloud.maps.d/{{ ENVIRONMENT }}_elasticsearch_map.yml
    - kwargs:
        parallel: True
    - require:
        - file: generate_elasticsearch_cloud_map_file

sync_external_modules_for_elasticsearch_nodes:
  salt.function:
    - name: saltutil.sync_all
    - tgt: '{{ target_string }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound

format_data_drive:
  salt.function:
    - tgt: '{{ target_string }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound
    - name: state.single
    - arg:
        - blockdev.formatted
    - kwarg:
        name: /dev/nvme1n1
        fs_type: ext4
    - require:
        - salt: deploy_elasticsearch_nodes

mount_data_drive:
  salt.function:
    - tgt: '{{ target_string }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound
    - name: state.single
    - arg:
        - mount.mounted
    - kwarg:
        name: /var/lib/elasticsearch
        device: /dev/nvme1n1
        fstype: ext4
        mkmnt: True
    - require:
        - salt: format_data_drive

load_pillar_data_on_{{ ENVIRONMENT }}_elasticsearch_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: '{{ target_string }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound
    - require:
        - salt: deploy_elasticsearch_nodes

populate_mine_with_{{ ENVIRONMENT }}_elasticsearch_data:
  salt.function:
    - name: mine.update
    - tgt: '{{ target_string }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound
    - require:
        - salt: load_pillar_data_on_{{ ENVIRONMENT }}_elasticsearch_nodes

{# Reload the pillar data to update values from the salt mine #}
reload_pillar_data_on_{{ ENVIRONMENT }}_elasticsearch_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: '{{ target_string }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound
    - require:
        - salt: populate_mine_with_{{ ENVIRONMENT }}_elasticsearch_data

build_{{ ENVIRONMENT }}_elasticsearch_nodes:
  salt.state:
    - tgt: '{{ target_string }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound
    - highstate: True
    - require:
        - salt: reload_pillar_data_on_{{ ENVIRONMENT }}_elasticsearch_nodes
