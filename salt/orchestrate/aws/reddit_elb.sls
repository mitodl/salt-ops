{% from "orchestrate/aws_env_macro.jinja" import VPC_NAME, VPC_RESOURCE_SUFFIX,
 BUSINESS_UNIT, ENVIRONMENT, subnet_ids with context %}
{% set env_settings = salt.pillar.get('environments:{}'.format(ENVIRONMENT)) %}
{% set security_groups = 'webapp-{}'.format(ENVIRONMENT) %}
{% set app_name = 'reddit' %}
{% set elb_name = 'discussions-{}-{}'.format(app_name, ENVIRONMENT)[:32].strip('-') %}

{% set instance_ids = [] %}
{% for id, grains in salt.saltutil.runner(
    'mine.get',
    tgt='G@roles:reddit and G@environment:{}'.format(ENVIRONMENT),
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
        - name: discussions-{{ app_name }}-{{ ENVIRONMENT }}.odl.mit.edu
          zone: odl.mit.edu.
          ttl: 60
    - health_check:
        target: 'HTTPS:443/'
    - subnets: {{ subnet_ids }}
    - security_groups: {{ security_groups }}
    - tags:
        Name: {{ elb_name }}
        business_unit: {{ BUSINESS_UNIT }}

register_{{ app_name }}_nodes_with_elb:
  boto_elb.register_instances:
    - name: {{ elb_name }}
    - instances: {{ instance_ids }}
    - require:
        - boto_elb: create_elb_for_{{ app_name }}_{{ ENVIRONMENT }}
