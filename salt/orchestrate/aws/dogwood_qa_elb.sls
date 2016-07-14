{% set type_counts = {'draft': 4, 'live': 6} %}
{% set environment = 'dogwood-qa' %}
{% for edx_type in ['draft', 'live'] %}
create_elb_for_edx_{{ edx_type }}:
  boto_elb.present:
    - name: edx-{{ edx_type }}-dogwood-qa
    - availability_zones:
        - us-east-1b
        - us-east-1c
        - us-east-1d
    - listeners:
        - elb_port: 443
          instance_port: 443
          elb_protocol: TCP
          instance_protocol: HTTPS
        - elb_port: 80
          instance_port: 80
          elb_protocol: HTTP
          instance_protocol: HTTP
    - attributes:
        cross_zone_load_balancing:
          enabled: True
    - cnames:
        - name: dogwood-qa.{{ edx_type }}.mitx.mit.edu.
          zone: mitx.mit.edu.
          ttl: 60
        - name: studio-dogwood-qa.{{ edx_type }}.mitx.mit.edu.
          zone: mitx.mit.edu.
          ttl: 60
    - health_check:
        target: 'HTTPS:443/heartbeat'

register_edx_{{ edx_type }}_nodes_with_elb:
  boto_elb.register_instances:
    - name: edx-{{ edx_type }}-dogwood-qa
    - instances:
        {% for instance_num in range(type_counts[edx_type]) %}
        - {{ salt.boto_ec2.get_id('edx-{env}-{t}-{num}'.format(
            env=environment, t=edx_type, num=instance_num)) }}
        {% endfor %}
{% endfor %}
