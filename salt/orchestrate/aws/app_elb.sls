{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT', 'rc-apps') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set app_name = salt.environ.get('APP_NAME') %}
{% set purpose = env_data.purposes[app_name] %}
{% set VPC_NAME = env_data.vpc_name %}
{% set BUSINESS_UNIT = env_data.purposes[app_name].get('business_unit', env_data.business_unit) %}
{% set subnet_ids = salt.boto_vpc.describe_subnets(
    vpc_id=salt.boto_vpc.describe_vpcs(
        name=env_data.vpc_name).vpcs[0].id
    ).subnets|map(attribute='id')|list %}
{% set zone_names = salt.boto_route53.describe_hosted_zones()|map(attribute='Name')|list %}
{% set domains = purpose.domains %}
{% set security_groups = 'webapp-{}'.format(ENVIRONMENT) %}
{% set elb_name = '{}-{}'.format(app_name, ENVIRONMENT)[:32].strip('-') %}
{% set instance_ids = [] %}
{% for id, grains in salt.saltutil.runner(
    'mine.get',
    tgt='G@roles:{app} and G@environment:{env}'.format(app=app_name, env=ENVIRONMENT),
    fun='grains.item',
    tgt_type='compound').items() %}
{% do instance_ids.append(grains['instance-id']) %}
{% endfor %}

create_elb_for_{{ app_name }}_{{ ENVIRONMENT }}:
  boto_elb.present:
    - name: {{ elb_name }}
    - listeners:
        - elb_port: 443
          instance_port: 443
          elb_protocol: HTTPS
          instance_protocol: HTTPS
          certificate: arn:aws:acm:us-east-1:610119931565:certificate/9b249738-26bd-4dd8-b369-1027f9c298b9
    - attributes:
        cross_zone_load_balancing:
          enabled: True
        connection_draining:
          enabled: True
          timeout: 300
    - cnames:
    {% for zone_name in zone_names %}
    {% for domain in domains %}
    {% if zone_name.strip('.') in domain %}
        - name: {{ domain }}
          zone: {{ zone_name }}
          ttl: 60
    {% endif %}
    {% endfor %}
    {% endfor %}
    - health_check:
        target: HTTPS:443{{ purpose.get('healthcheck', '/status/?token={env}'.format(env=ENVIRONMENT)) }}
    - subnets: {{ subnet_ids|tojson }}
    - security_groups: {{ security_groups|tojson }}
    - tags:
        Name: {{ elb_name }}
        business_unit: {{ BUSINESS_UNIT }}

register_{{ app_name }}_nodes_with_elb:
  boto_elb.register_instances:
    - name: {{ elb_name }}
    - instances: {{ instance_ids|tojson }}
    - require:
        - boto_elb: create_elb_for_{{ app_name }}_{{ ENVIRONMENT }}
