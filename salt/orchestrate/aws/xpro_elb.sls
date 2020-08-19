{% set env_settings = salt.file.read(salt.cp.cache_file("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml"))|load_yaml %}
{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT', 'mitxpro-qa') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set PURPOSES = salt.environ.get('PURPOSES', 'xpro-qa').split(',') %}
{% set VPC_NAME = env_data.vpc_name %}
{% set BUSINESS_UNIT = salt.environ.get('BUSINESS_UNIT', env_data.business_unit) %}

{% set launch_date = salt.status.time(format="%Y-%m-%d") %}
{% set subnet_ids = salt.boto_vpc.describe_subnets(
    vpc_id=salt.boto_vpc.describe_vpcs(
        name=env_data.vpc_name).vpcs[0].id
    ).subnets|map(attribute='id')|list %}
{% set security_groups = salt.pillar.get('edx:lb_security_groups', ['default', 'edx-{env}'.format(env=ENVIRONMENT)]) %}
{% set defined_purposes = env_data.purposes %}

{% for purpose_name in PURPOSES %}
{% set codename = defined_purposes[purpose_name].versions.codename %}
{% set release_version = salt.sdb.get('sdb://consul/edxapp-{}-{}-release-version'.format(ENVIRONMENT, codename)) %}
{% set purpose = defined_purposes[purpose_name] %}
{% set domain_map = {
'xpro-production':{
          'cms': 'studio-xpro.mitx.mit.edu',
          'lms': 'xpro.mitx.mit.edu',
          'preview': 'preview-xpro.mitx.mit.edu'
          },
'xpro-qa': {
          'cms': 'studio-xpro-qa.mitx.mit.edu',
          'lms': 'xpro-qa.mitx.mit.edu',
          'preview': 'preview-xpro-qa.mitx.mit.edu'
  },
'sandbox': {
          'cms': 'studio-xpro-qa-sandbox.mitx.mit.edu',
          'lms': 'xpro-qa-sandbox.mitx.mit.edu',
          'preview': 'preview-xpro-qa-sandbox.mitx.mit.edu'
  }
} %}
{% set domains = domain_map[purpose] %}
{% set elb_name = 'edx-{purpose}-{env}'.format(
   purpose=purpose_name, env=ENVIRONMENT)[:32].strip('-') %}
create_elb_for_edx_{{ purpose_name }}:
  boto_elb.present:
    - name: {{ elb_name }}
    - listeners:
        - elb_port: 443
          instance_port: 443
          elb_protocol: HTTPS
          instance_protocol: HTTPS
          certificate:  arn:aws:acm:us-east-1:610119931565:certificate/133082a7-f4a2-483b-a013-e94d9d531364
        - elb_port: 80
          instance_port: 80
          elb_protocol: HTTP
          instance_protocol: HTTP
    - attributes:
        cross_zone_load_balancing:
          enabled: True
        connection_draining:
          enabled: True
          timeout: 300
    - cnames:
        {% for domain_key, domain in purpose.domains.items()  %}
        {% if domain_key != 'cms' %}
        - name: {{ domain }}.
          zone: mitx.mit.edu.
          ttl: 60
        {% endif %}
        {% endfor %}
    - health_check:
        target: 'HTTPS:443/heartbeat'
    - subnets: {{ subnet_ids|tojson }}
    - security_groups: {{ security_groups|tojson }}
    - policies:
        - policy_name: {{ elb_name }}-sticky-cookie-policy
          policy_type: LBCookieStickinessPolicyType
          policy: {}
    - tags:
        Name: {{ elb_name }}
        business_unit: {{ BUSINESS_UNIT }}
        created_at: "{{ launch_date }}"

register_edx_{{ purpose_name }}_nodes_with_elb:
  boto_elb.register_instances:
    - name: {{ elb_name }}
    - instances:
        {% for instance_num in range(purpose.instances.edx.number) %}
        - {{ salt.boto_ec2.get_id('edx-{env}-{t}-{num}-v{version}'.format(
            env=ENVIRONMENT, t=purpose_name, num=instance_num,
            version=release_version)) }}
        {% endfor %}
    - require:
        - boto_elb: create_elb_for_edx_{{ purpose_name }}

{% set elb_name = 'edx-{prefix}-studio-{env}'.format(
   prefix=purpose_name.rsplit('-', 1)[0], env=ENVIRONMENT)[:32].strip('-') %}
create_elb_for_edx_{{ purpose_name }}_studio:
  boto_elb.present:
    - name: {{ elb_name }}
    - listeners:
        - elb_port: 443
          instance_port: 443
          elb_protocol: HTTPS
          instance_protocol: HTTPS
          certificate:  arn:aws:acm:us-east-1:610119931565:certificate/133082a7-f4a2-483b-a013-e94d9d531364
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
        {% for domain_key, domain in purpose.domains.items()  %}
        {% if domain_key == 'cms' %}
        - name: {{ domain }}.
          zone: mitx.mit.edu.
          ttl: 60
        {% endif %}
        {% endfor %}
    - health_check:
        target: 'HTTPS:443/heartbeat'
    - subnets: {{ subnet_ids|tojson }}
    - security_groups: {{ security_groups|tojson }}
    - policies:
        - policy_name: {{ elb_name }}-sticky-cookie-policy
          policy_type: LBCookieStickinessPolicyType
          policy: {}
    - tags:
        Name: {{ elb_name }}
        business_unit: {{ BUSINESS_UNIT }}
        created_at: "{{ launch_date }}"

register_edx_{{ purpose_name }}_studio_nodes_with_elb:
  boto_elb.register_instances:
    - name: {{ elb_name }}
    - instances:
        {% for instance_num in range(purpose.instances.edx.number) %}
        - {{ salt.boto_ec2.get_id('edx-{env}-{t}-{num}-v{version}'.format(
            env=ENVIRONMENT, t=purpose_name, num=instance_num,
            version=release_version)) }}
        {% endfor %}
    - require:
        - boto_elb: create_elb_for_edx_{{ purpose_name }}_studio
{% endfor %}
