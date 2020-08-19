{% set env_settings = salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml", dest=None)|load_yaml %}
{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT', 'rc-apps') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set VPC_NAME = env_data.vpc_name %}
{% set INSTANCE_COUNT = salt.environ.get('INSTANCE_COUNT', 3) %}
{% set BUSINESS_UNIT = salt.environ.get('BUSINESS_UNIT', env_data.business_unit) %}
{% set launch_date = salt.status.time(format="%Y-%m-%d") %}
{% set subnet_ids = salt.boto_vpc.describe_subnets(
    vpc_id=salt.boto_vpc.describe_vpcs(
        name=env_data.vpc_name).vpcs[0].id
    ).subnets|rejectattr('availability_zone', 'equalto', 'us-east-1e')|map(attribute='id')|list %}
{% set app_name = 'consul' %}
{% set release_id = salt.sdb.get('sdb://consul/' ~ app_name ~ '/' ~ ENVIRONMENT ~ '/release-id')|default('v1') %}
{% set target_string = app_name ~ '-' ~ ENVIRONMENT ~ '-*-' ~ release_id %}

load_consul_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/consul.conf
    - source: salt://orchestrate/aws/cloud_profiles/consul.conf
    - template: jinja

generate_cloud_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/{{ ENVIRONMENT }}_consul_map.yml
    - source: salt://orchestrate/aws/map_templates/instance_map.yml
    - template: jinja
    - makedirs: True
    - context:
        num_instances: {{ INSTANCE_COUNT }}
        service_name: consul
        release_id: {{ release_id }}
        tags:
          business_unit: {{ BUSINESS_UNIT }}
          Department: {{ BUSINESS_UNIT }}
          OU: {{ BUSINESS_UNIT }}
          Environment: {{ ENVIRONMENT }}
        environment_name: {{ ENVIRONMENT }}
        roles:
          - consul_server
          - service_discovery
        securitygroupid:
          - {{ salt.boto_secgroup.get_group_id(
            'consul-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          - {{ salt.boto_secgroup.get_group_id(
            'master-ssh-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          - {{ salt.boto_secgroup.get_group_id(
            'consul-agent-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
        subnetids: {{ subnet_ids|tojson }}
    - require:
        - file: load_consul_cloud_profile

deploy_consul_nodes:
  salt.runner:
    - name: cloud.map_run
    - path: /etc/salt/cloud.maps.d/{{ ENVIRONMENT }}_consul_map.yml
    - kwargs:
        parallel: True
    - require:
        - file: generate_cloud_map_file

sync_external_modules_for_consul_nodes:
  salt.function:
    - name: saltutil.sync_all
    - tgt: {{ target_string }}

load_pillar_data_on_{{ ENVIRONMENT }}_consul_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: {{ target_string }}
    - require:
        - salt: deploy_consul_nodes

populate_mine_with_{{ ENVIRONMENT }}_consul_data:
  salt.function:
    - name: mine.update
    - tgt: {{ target_string }}
    - require:
        - salt: load_pillar_data_on_{{ ENVIRONMENT }}_consul_nodes

{# Reload the pillar data to update values from the salt mine #}
reload_pillar_data_on_{{ ENVIRONMENT }}_consul_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: {{ target_string }}
    - require:
        - salt: populate_mine_with_{{ ENVIRONMENT }}_consul_data

build_{{ ENVIRONMENT }}_consul_nodes:
  salt.state:
    - tgt: {{ target_string }}
    - highstate: True
    - require:
        - salt: reload_pillar_data_on_{{ ENVIRONMENT }}_consul_nodes

ensure_query_templates_are_present:
  salt.state:
    - tgt: {{ target_string }}
    - sls: consul.query_template
    - subset: 1
