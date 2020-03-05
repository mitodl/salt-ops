{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT', 'operations-qa') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set purpose_data = env_data.purposes.pulsar|default({}) %}
{% set VPC_NAME = env_data.vpc_name %}
{% set INSTANCE_COUNT = salt.environ.get('INSTANCE_COUNT', purpose_data.get('num_instances', 3)) %}
{% set BUSINESS_UNIT = salt.environ.get('BUSINESS_UNIT', env_data.business_unit) %}
{% set launch_date = salt.status.time(format="%Y-%m-%d") %}
{% set subnet_ids = salt.boto_vpc.describe_subnets(
    vpc_id=salt.boto_vpc.describe_vpcs(
        name=env_data.vpc_name).vpcs[0].id
    ).subnets|rejectattr('availability_zone', 'equalto', 'us-east-1e')|map(attribute='id')|list %}
{% set app_name = 'pulsar' %}
{% set release_id = salt.sdb.get('sdb://consul/'
~ app_name ~ '/' ~ ENVIRONMENT ~ '/release-id') %}
{% if not release_id %}
{% set release_id = 'v1' %}
{% endif %}
{% set target_string = app_name ~ '-' ~ ENVIRONMENT ~ '-*-' ~ release_id %}

ensure_pulsar_instance_profile_exists:
  boto_iam_role.present:
    - name: pulsar-instance-role

load_bookkeeper_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/bookkeeper.conf
    - source: salt://orchestrate/aws/cloud_profiles/bookkeeper.conf
    - template: jinja

generate_cloud_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/{{ ENVIRONMENT }}_bookkeeper_map.yml
    - source: salt://orchestrate/aws/map_templates/instance_map.yml
    - template: jinja
    - makedirs: True
    - context:
        num_instances: {{ INSTANCE_COUNT }}
        service_name: bookkeeper
        release_id: {{ release_id }}
        tags:
          business_unit: {{ BUSINESS_UNIT }}
          Department: {{ BUSINESS_UNIT }}
          OU: {{ BUSINESS_UNIT }}
          Environment: {{ ENVIRONMENT }}
        environment_name: {{ ENVIRONMENT }}
        roles:
          - bookkeeper
          - pulsar
        securitygroupid:
          - {{ salt.boto_secgroup.get_group_id(
            'pulsar-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          - {{ salt.boto_secgroup.get_group_id(
            'bookkeeper-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          - {{ salt.boto_secgroup.get_group_id(
            'master-ssh-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          - {{ salt.boto_secgroup.get_group_id(
            'consul-agent-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
        subnetids: {{ subnet_ids|tojson }}
    - require:
        - file: load_bookkeeper_cloud_profile

deploy_bookkeeper_nodes:
  salt.runner:
    - name: cloud.map_run
    - path: /etc/salt/cloud.maps.d/{{ ENVIRONMENT }}_bookkeeper_map.yml
    - kwargs:
        parallel: True
    - require:
        - file: generate_cloud_map_file

sync_external_modules_for_bookkeeper_nodes:
  salt.function:
    - name: saltutil.sync_all
    - tgt: {{ target_string }}

format_journal_drive:
  salt.function:
    - tgt: '{{ target_string }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound
    - name: state.single
    - arg:
        - blockdev.formatted
    - kwarg:
        name: /dev/xvdb
        fs_type: ext4
    - require:
        - salt: deploy_bookkeeper_nodes

mount_journal_drive:
  salt.function:
    - tgt: '{{ target_string }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound
    - name: state.single
    - arg:
        - mount.mounted
    - kwarg:
        name: /var/opt/bookkeeper-journal
        device: /dev/xvdb
        fstype: ext4
        mkmnt: True
    - require:
        - salt: format_journal_drive

format_ledger_drive:
  salt.function:
    - tgt: '{{ target_string }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound
    - name: state.single
    - arg:
        - blockdev.formatted
    - kwarg:
        name: /dev/xvdc
        fs_type: ext4
    - require:
        - salt: deploy_bookkeeper_nodes

mount_ledger_drive:
  salt.function:
    - tgt: '{{ target_string }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound
    - name: state.single
    - arg:
        - mount.mounted
    - kwarg:
        name: /var/opt/bookkeeper-ledger
        device: /dev/xvdc
        fstype: ext4
        mkmnt: True
    - require:
        - salt: format_journal_drive

load_pillar_data_on_{{ ENVIRONMENT }}_bookkeeper_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: {{ target_string }}
    - require:
        - salt: deploy_bookkeeper_nodes

populate_mine_with_{{ ENVIRONMENT }}_bookkeeper_data:
  salt.function:
    - name: mine.update
    - tgt: {{ target_string }}
    - require:
        - salt: load_pillar_data_on_{{ ENVIRONMENT }}_bookkeeper_nodes

{# Reload the pillar data to update values from the salt mine #}
reload_pillar_data_on_{{ ENVIRONMENT }}_bookkeeper_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: {{ target_string }}
    - require:
        - salt: populate_mine_with_{{ ENVIRONMENT }}_bookkeeper_data

build_{{ ENVIRONMENT }}_bookkeeper_nodes:
  salt.state:
    - tgt: {{ target_string }}
    - highstate: True
    - require:
        - salt: reload_pillar_data_on_{{ ENVIRONMENT }}_bookkeeper_nodes
