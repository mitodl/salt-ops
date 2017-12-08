{% from "orchestrate/aws_env_macro.jinja" import VPC_NAME, VPC_RESOURCE_SUFFIX,
 ENVIRONMENT, BUSINESS_UNIT, PURPOSE_PREFIX, subnet_ids with context %}
{% set INSTANCE_COUNT = salt.environ.get('INSTANCE_COUNT', 2) %}
{% set app_name = 'fluentd' %}

load_{{ app_name }}_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/{{ app_name }}.conf
    - source: salt://orchestrate/aws/cloud_profiles/{{ app_name }}.conf
    - template: jinja

generate_{{ app_name }}_cloud_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/{{ VPC_RESOURCE_SUFFIX }}_{{ app_name }}_map.yml
    - source: salt://orchestrate/aws/map_templates/instance_map.yml
    - template: jinja
    - makedirs: True
    - context:
        environment_name: {{ ENVIRONMENT }}
        num_instances: {{ INSTANCE_COUNT }}
        service_name: {{ app_name }}
        roles:
          - fluentd-server
          - log-aggregator
          - {{ app_name }}
        securitygroupid:
          - {{ salt.boto_secgroup.get_group_id(
            'default', vpc_name='mitodl-operations-services') }}
          - {{ salt.boto_secgroup.get_group_id(
            'fluentd-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          - {{ salt.boto_secgroup.get_group_id(
            'salt_master-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          - {{ salt.boto_secgroup.get_group_id(
            'consul-agent-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
        subnetids: {{ subnet_ids }}
        tags:
          business_unit: {{ BUSINESS_UNIT }}
          Department: {{ BUSINESS_UNIT }}
          OU: {{ BUSINESS_UNIT }}
          Environment: {{ ENVIRONMENT }}
    - require:
        - file: load_{{ app_name }}_cloud_profile

ensure_instance_profile_exists_for_{{ app_name }}:
  boto_iam_role.present:
    - name: {{ app_name }}-instance-role

deploy_{{ app_name }}_cloud_map:
  salt.function:
    - tgt: 'roles:master'
    - tgt_type: grain
    - name: saltutil.runner
    - arg:
        - cloud.map_run
    - kwarg:
        path: /etc/salt/cloud.maps.d/{{ VPC_RESOURCE_SUFFIX }}_{{ app_name }}_map.yml
        parallel: True
        full_return: True
    - require:
        - file: generate_{{ app_name }}_cloud_map_file

load_pillar_data_on_{{ app_name }}_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'P@roles:{{ app_name }} and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - require:
        - salt: deploy_{{ app_name }}_cloud_map

populate_mine_with_{{ app_name }}_node_data:
  salt.function:
    - name: mine.update
    - tgt: 'G@roles:{{ app_name }} and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - require:
        - salt: load_pillar_data_on_{{ app_name }}_nodes

deploy_consul_agent_to_{{ app_name }}_nodes:
  salt.state:
    - tgt: 'G@roles:{{ app_name }} and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - sls:
        - consul
        - consul.dns_proxy

build_{{ app_name }}_nodes:
  salt.state:
    - tgt: 'G@roles:{{ app_name }} and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - highstate: True
    - require:
        - salt: deploy_consul_agent_to_{{ app_name }}_nodes

restart_{{ app_name }}_service:
  salt.function:
    - tgt: 'G@roles:{{ app_name }} and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - name: service.restart
    - arg:
        - {{ app_name }}
    - require:
        - salt: build_{{ app_name }}_nodes
