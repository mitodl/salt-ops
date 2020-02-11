{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT', 'mitx-qa') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set app_name = 'xqwatcher' %}
{% set VPC_NAME = env_data.vpc_name %}
{% set BUSINESS_UNIT = env_data.purposes[app_name].business_unit %}
{% set release_id = salt.sdb.get('sdb://consul/' ~ app_name ~ '/' ~ ENVIRONMENT ~ '/release-id')|default('v1') %}
{% set subnet_ids = salt.boto_vpc.describe_subnets(
    vpc_id=salt.boto_vpc.describe_vpcs(
        name=env_data.vpc_name).vpcs[0].id
    ).subnets|map(attribute='id')|list %}

load_xqwatcher_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/xqwatcher.conf
    - source: salt://orchestrate/aws/cloud_profiles/xqwatcher.conf
    - template: jinja

ensure_instance_profile_exists_for_xqwatcher:
  boto_iam_role.present:
    - name: xqwatcher-instance-role

{% for course in env_data.purposes[app_name].courses %}
{% set INSTANCE_COUNT = course.num_instances %}
{% set security_groups = course.get('security_groups', []) %}
{% do security_groups.extend(['master-ssh', 'consul-agent']) %}
generate_xqwatcher_{{ course.name }}_cloud_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/{{ ENVIRONMENT }}_xqwatcher_map.yml
    - source: salt://orchestrate/aws/map_templates/instance_map.yml
    - template: jinja
    - makedirs: True
    - context:
        profile_name: xqwatcher
        service_name: xqwatcher-{{ course.name }}
        environment_name: {{ ENVIRONMENT }}
        num_instances: {{ INSTANCE_COUNT }}
        release_id: {{ release_id }}
        tags:
          business_unit: {{ BUSINESS_UNIT }}
          Department: {{ BUSINESS_UNIT }}
          OU: {{ BUSINESS_UNIT }}
          Environment: {{ ENVIRONMENT }}
          course: {{ course.name }}
        roles:
          - xqwatcher
        securitygroupid:
          {% for group_name in security_groups %}
          - {{ salt.boto_secgroup.get_group_id(
            '{}-{}'.format(group_name, ENVIRONMENT), vpc_name=VPC_NAME) }}
          {% endfor %}
        subnetids: {{ subnet_ids|tojson }}
    - require:
        - file: load_xqwatcher_cloud_profile

deploy_xqwatcher_{{ course.name }}_cloud_map:
  salt.runner:
    - name: cloud.map_run
    - path: /etc/salt/cloud.maps.d/{{ ENVIRONMENT}}_xqwatcher_map.yml
    - kwargs:
        parallel: True
    - require:
        - file: generate_xqwatcher_{{ course.name }}_cloud_map_file
{% endfor %}

build_xqwatcher_nodes:
  salt.state:
    - tgt: 'G@roles:xqwatcher and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - highstate: True
