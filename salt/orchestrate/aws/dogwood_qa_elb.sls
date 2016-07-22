{% set type_counts = {'draft': 4, 'live': 6} %}
{% set environment = 'dogwood-qa' %}
{% set security_groups = salt.pillar.get('edx:lb_security_groups', ['default', 'edx-dogwood_qa']) %}
{% set subnet_ids = [] %}
{% for subnet in salt.boto_vpc.describe_subnets(subnet_names=[
    'public1-dogwood_qa', 'public2-dogwood_qa', 'public3-dogwood_qa'])['subnets'] %}
{% do subnet_ids.append('{0}'.format(subnet['id'])) %}
{% endfor %}

{% for edx_type in ['draft', 'live'] %}
create_elb_for_edx_{{ edx_type }}:
  boto_elb.present:
    - name: edx-{{ edx_type }}-dogwood-qa
    - listeners:
        - elb_port: 443
          instance_port: 443
          elb_protocol: HTTPS
          instance_protocol: HTTPS
          certificate: arn:aws:iam::610119931565:server-certificate/mitx-wildcard-cert
        - elb_port: 80
          instance_port: 80
          elb_protocol: HTTP
          instance_protocol: HTTP
    - attributes:
        cross_zone_load_balancing:
          enabled: True
    - cnames:
        - name: dogwood-qa-{{ edx_type }}.mitx.mit.edu.
          zone: mitx.mit.edu.
          ttl: 60
        - name: preview.dogwood-qa-{{ edx_type }}.mitx.mit.edu.
          zone: mitx.mit.edu.
          ttl: 60
        - name: studio-dogwood-qa-{{ edx_type }}.mitx.mit.edu.
          zone: mitx.mit.edu.
          ttl: 60
    - health_check:
        target: 'HTTPS:443/heartbeat'
    - subnets: {{ subnet_ids }}
    - security_groups: {{ security_groups }}

register_edx_{{ edx_type }}_nodes_with_elb:
  boto_elb.register_instances:
    - name: edx-{{ edx_type }}-dogwood-qa
    - instances:
        {% for instance_num in range(type_counts[edx_type]) %}
        - {{ salt.boto_ec2.get_id('edx-{env}-{t}-{num}'.format(
            env=environment, t=edx_type, num=instance_num)) }}
        {% endfor %}
    - require:
        - boto_elb: create_elb_for_edx_{{ edx_type }}
{% endfor %}
