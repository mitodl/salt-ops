{% set app_name = 'reddit' %}
{% set env_settings = salt.file.read(salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml"))|load_yaml %}
{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT', 'rc-apps') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set VPC_NAME = env_data.vpc_name %}
{% set INSTANCE_COUNT = salt.environ.get('INSTANCE_COUNT', env_data.purposes[app_name].num_instances) %}
{% set BUSINESS_UNIT = env_data.purposes[app_name].business_unit %}
{% set subnet_ids = salt.boto_vpc.describe_subnets(
    vpc_id=salt.boto_vpc.describe_vpcs(
        name=env_data.vpc_name).vpcs[0].id
    ).subnets|map(attribute='id')|list %}
{% set security_groups = env_data.purposes[app_name].get('security_groups', []) %}
{% do security_groups.extend(['master-ssh', 'consul-agent']) %}

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
        release_id: {{ salt.sdb.get('sdb://consul/{{ app_name }}/{{ ENVIRONMENT }}/release-id')|default('v1') }}
        roles:
          - {{ app_name }}
        securitygroupid:
          {% for group_name in security_groups %}
          - {{ salt.boto_secgroup.get_group_id(
            '{}-{}'.format(group_name, ENVIRONMENT), vpc_name=VPC_NAME) }}
          {% endfor %}
        subnetids: {{ subnet_ids|tojson }}
        tags:
          app: {{ app_name }}
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
  salt.runner:
    - name: cloud.map_run
    - path: /etc/salt/cloud.maps.d/{{ ENVIRONMENT }}_{{ app_name }}_map.yml
    - kwargs:
        parallel: True
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

execute_post_install_scripts:
  salt.state:
    - tgt: 'G@roles:{{ app_name }} and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    {% if INSTANCE_COUNT > 1 %}
    - subset: 1
    {% endif %}
    - sls:
        - reddit.post_install

restart_{{ app_name }}_service:
  salt.function:
    - tgt: 'G@roles:{{ app_name }} and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - name: cmd.run
    - arg:
        - reddit-restart
    - require:
        - salt: build_{{ app_name }}_nodes
