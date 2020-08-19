{% set env_settings = salt.file.read(salt.cp.cache_file("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml"))|load_yaml %}
{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT', 'operations') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set app_name = salt.environ.get('APP_NAME', 'fluentd') %}
{% set VPC_NAME = env_data.vpc_name %}
{% set INSTANCE_COUNT = salt.environ.get('INSTANCE_COUNT', 2) %}
{% set BUSINESS_UNIT = salt.environ.get('BUSINESS_UNIT', env_data.business_unit) %}
{% set launch_date = salt.status.time(format="%Y-%m-%d") %}
{% set release_id = (salt.sdb.get('sdb://consul/' ~ app_name ~ '/' ~ ENVIRONMENT ~ '/release-id') or 'v1') %}
{% set subnet_ids = salt.boto_vpc.describe_subnets(
    vpc_id=salt.boto_vpc.describe_vpcs(
        name=env_data.vpc_name).vpcs[0].id
    ).subnets|rejectattr('availability_zone', 'equalto', 'us-east-1e')|map(attribute='id')|list %}

create_fluentd_aggregator_security_group:
  boto_secgroup.present:
    - name: fluentd-{{ ENVIRONMENT }}
    - vpc_name: {{ VPC_NAME }}
    - description: ACL for Fluentd aggretators
    - rules:
        {% for portnum in [443, 5001] %}
        - ip_protocol: tcp
          from_port: {{ portnum }}
          to_port: {{ portnum }}
          cidr_ip:
            - 0.0.0.0/0
            - '::/0'
        {% endfor %}
    - tags:
        Name: fluentd-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

load_{{ app_name }}_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/{{ app_name }}.conf
    - source: salt://orchestrate/aws/cloud_profiles/{{ app_name }}.conf
    - template: jinja

generate_{{ app_name }}_cloud_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/{{ ENVIRONMENT }}_{{ app_name }}_map.yml
    - source: salt://orchestrate/aws/map_templates/instance_map.yml
    - template: jinja
    - makedirs: True
    - context:
        environment_name: {{ ENVIRONMENT }}
        num_instances: {{ INSTANCE_COUNT }}
        service_name: {{ app_name }}
        release_id: {{ release_id }}
        securitygroupid:
          - {{ salt.boto_secgroup.get_group_id(
            'default', vpc_name=VPC_NAME) }}
          - {{ salt.boto_secgroup.get_group_id(
            'fluentd-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          - {{ salt.boto_secgroup.get_group_id(
            'consul-agent-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
        subnetids: {{ subnet_ids|tojson }}
        tags:
          business_unit: {{ BUSINESS_UNIT }}
          Department: {{ BUSINESS_UNIT }}
          OU: {{ BUSINESS_UNIT }}
          Environment: {{ ENVIRONMENT }}
          launch-date: {{ launch_date }}
        roles:
          - fluentd
          - fluentd-server
          - log-aggregator
    - require:
        - file: load_{{ app_name }}_cloud_profile

ensure_instance_profile_exists_for_{{ app_name }}:
  boto_iam_role.present:
    - name: {{ app_name }}-instance-role

deploy_{{ app_name }}_cloud_map:
  salt.runner:
    - name: cloud.map_run
    - path: /etc/salt/cloud.maps.d/{{ ENVIRONMENT }}_{{ app_name }}_map.yml
    - kwarg:
        parallel: True
        full_return: True
    - require:
        - file: generate_{{ app_name }}_cloud_map_file

load_pillar_data_on_{{ app_name }}_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:{{ app_name }} and G@environment:{{ ENVIRONMENT }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound
    - require:
        - salt: deploy_{{ app_name }}_cloud_map

populate_mine_with_{{ app_name }}_node_data:
  salt.function:
    - name: mine.update
    - tgt: 'G@roles:{{ app_name }} and G@environment:{{ ENVIRONMENT }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound
    - require:
        - salt: load_pillar_data_on_{{ app_name }}_nodes

build_{{ app_name }}_nodes:
  salt.state:
    - tgt: 'G@roles:{{ app_name }} and G@environment:{{ ENVIRONMENT }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound
    - highstate: True
    - require:
        - salt: deploy_{{ app_name }}_cloud_map

update_mine_with_{{ app_name }}_node_data:
  salt.function:
    - name: mine.update
    - tgt: 'G@roles:{{ app_name }} and G@environment:{{ ENVIRONMENT }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound
    - require:
        - salt: build_{{ app_name }}_nodes

{% set hosts = [] %}
{% for host, grains in salt.saltutil.runner(
    'mine.get',
    tgt='G@roles:fluentd and G@roles:log-aggregator', fun='grains.item', tgt_type='compound'
    ).items() %}
{% do hosts.append(grains['external_ip']) %}
{% endfor %}

{#
register_log_aggregator_dns:
  boto_route53.present:
    - name: log-input.odl.mit.edu
    - value: {{ hosts|tojson }}
    - zone: odl.mit.edu.
    - record_type: A
#}
