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

generate_ocw_db_cloud_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/{{ ENVIRONMENT }}/_ocw_db_map.yml
    - source: salt://orchestrate/aws/map_templates/instance_map.yml
    - template: jinja
    - makedirs: True
    - context:
        service_name: ocw_db
        environment_name: {{ ENVIRONMENT }}
        num_instances: {{ INSTANCE_COUNT }}
        roles:
          - ocw-db

        securitygroupid:
          - {{ salt.boto_secgroup.get_group_id(
            'ocw-db-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          - {{ salt.boto_secgroup.get_group_id(
            'salt_master-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          - {{ salt.boto_secgroup.get_group_id(
            'consul-agent-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
        subnetids: {{ subnet_ids|tojson }}
        tags:
          business_unit: {{ BUSINESS_UNIT }}
          Department: {{ BUSINESS_UNIT }}
          OU: {{ BUSINESS_UNIT }}
          Environment: {{ ENVIRONMENT }}
          launch-date: {{ launch-date }}
        profile_overrides:
          ebs_optimized: False
          size: r4.large
          block_device_mappings:
            - DeviceName: /dev/xvda
              Ebs.VolumeSize: 100
              Ebs.VolumeType: gp2
            - DeviceName: /dev/xvdf
              Ebs.VolumeSize: 300
              Ebs.VolumeType: gp2

deploy_ocw_db_nodes:
  salt.runner:
    - name: cloud.map_run
    - path: /etc/salt/cloud.maps.d/{{ ENVIRONMENT }}/_ocw_db_map.yml
    - require:
        - file: generate_ocw_db_cloud_map_file

format_ocw_db_data_drive:
  salt.function:
    - tgt: 'G@roles:ocw-db and G@environment:{{ ENVIRONMENT }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound
    - name: state.single
    - arg:
        - blockdev.formatted
    - kwarg:
        name: /dev/xvdf
        fs_type: ext4
    - require:
        - salt: deploy_ocw_db_nodes

mount_data_drive:
  salt.function:
    - tgt: 'G@roles:ocw-db and G@environment:{{ ENVIRONMENT }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound
    - name: state.single
    - arg:
        - mount.mounted
    - kwarg:
        name: /zeo
        device: /dev/xvdf
        fstype: ext4
        mkmnt: True
        opts: 'defaults,nofail'
    - require:
        - salt: format_ocw_db_data_drive
