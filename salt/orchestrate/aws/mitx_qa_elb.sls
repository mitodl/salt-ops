{% set type_counts = {'draft': 2, 'live': 2} %}
{% set domains = {
    'draft': ['studio-mitx-qa-draft.mitx.mit.edu.',
              'mitx-qa-draft.mitx.mit.edu.',
              'preview-mitx-qa-draft.mitx.mit.edu.',
              'gr-qa.mitx.mit.edu.'],
    'live': ['studio-mitx-qa.mitx.mit.edu.',
             'mitx-qa.mitx.mit.edu.',
             'preview-mitx-qa.mitx.mit.edu.',
             'prod-gr-qa.mitx.mit.edu.']
} %}
{% set environment = 'mitx-qa' %}
{% set security_groups = salt.pillar.get('edx:lb_security_groups', ['default', 'edx-mitx-qa']) %}
{% set subnet_ids = [] %}
{% for subnet in salt.boto_vpc.describe_subnets(subnet_names=[
    'public1-mitx-qa', 'public2-mitx-qa', 'public3-mitx-qa'])['subnets'] %}
{% do subnet_ids.append('{0}'.format(subnet['id'])) %}
{% endfor %}

{% for edx_type in ['draft', 'live'] %}
{% set elb_name = 'edx-{0}-mitx-qa'.format(edx_type) %}
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
        {% for domain in domains[edx_type] %}
        - name: {{ domain }}
          zone: mitx.mit.edu.
          ttl: 60
        {% endfor %}
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
    - name: edx-{{ edx_type }}-mitx-qa
    - instances:
        {% for instance_num in range(type_counts[edx_type]) %}
        - {{ salt.boto_ec2.get_id('edx-{env}-{t}-{num}'.format(
            env=environment, t=edx_type, num=instance_num)) }}
        {% endfor %}
    - require:
        - boto_elb: create_elb_for_edx_{{ edx_type }}
{% endfor %}
