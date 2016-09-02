{% set type_counts = {'draft': 4, 'live': 6} %}
{% set environment = 'dogwood-rp' %}
{% set security_groups = salt.pillar.get('edx:lb_security_groups', ['default', 'edx-dogwood-rp']) %}
{% set subnet_ids = [] %}
{% for subnet in salt.boto_vpc.describe_subnets(subnet_names=[
    'public1-dogwood-rp', 'public2-dogwood-rp', 'public3-dogwood-rp'])['subnets'] %}
{% do subnet_ids.append('{0}'.format(subnet['id'])) %}
{% endfor %}

{% for edx_type in ['draft', 'live'] %}
{% set elb_name = 'edx-{0}-dogwood-rp'.format(edx_type) %}

create_elb_for_edx_{{ edx_type }}:
  boto_elb.present:
    - name: {{ elb_name }}
    - listeners:
        - elb_port: 443
          instance_port: 443
          elb_protocol: HTTPS
          instance_protocol: HTTPS
          certificate: arn:aws:iam::610119931565:server-certificate/mitx-wildcard-cert
          policies:
            - {{ elb_name }}-sticky-cookie-policy
        - elb_port: 80
          instance_port: 80
          elb_protocol: HTTP
          instance_protocol: HTTP
          policies:
            - {{ elb_name }}-sticky-cookie-policy
    - attributes:
        cross_zone_load_balancing:
          enabled: True
        connection_draining:
          enabled: True
          timeout: 300
    - cnames:
        {% if edx_type == 'draft' %}
        {% for domain in ['staging', 'preview', 'preview-rp', 'studio', 'studio-rp', 'gr-rp'] %}
        - name: {{ domain }}.mitx.mit.edu.
          zone: mitx.mit.edu.
          ttl: 60
        {% endfor %}
        {% else %}
        {% for domain in ['lms', 'lms-rp', 'prod-gr-rp'] %}
        - name: {{ domain }}.mitx.mit.edu.
          zone: mitx.mit.edu.
          ttl: 60
        {% endfor %}
        {% endif %}
        - name: dogwood-rp-{{ edx_type }}.mitx.mit.edu.
          zone: mitx.mit.edu.
          ttl: 60
        - name: preview-dogwood-rp-{{ edx_type }}.mitx.mit.edu.
          zone: mitx.mit.edu.
          ttl: 60
        - name: studio-dogwood-rp-{{ edx_type }}.mitx.mit.edu.
          zone: mitx.mit.edu.
          ttl: 60
    - health_check:
        target: 'HTTPS:443/heartbeat'
    - subnets: {{ subnet_ids }}
    - security_groups: {{ security_groups }}
    - policies:
        - policy_name: {{ elb_name }}-sticky-cookie-policy
          policy_type: LBCookieStickinessPolicyType
          policy: {}

register_edx_{{ edx_type }}_nodes_with_elb:
  boto_elb.register_instances:
    - name: edx-{{ edx_type }}-dogwood-rp
    - instances:
        {% for instance_num in range(type_counts[edx_type]) %}
        - {{ salt.boto_ec2.get_id('edx-{env}-{t}-{num}'.format(
            env=environment, t=edx_type, num=instance_num)) }}
        {% endfor %}
    - require:
        - boto_elb: create_elb_for_edx_{{ edx_type }}
{% endfor %}
