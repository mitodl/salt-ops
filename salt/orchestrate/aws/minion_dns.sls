{% set instance_id = salt.environ.get('MINION_ID') %}
{% set domain = salt.environ.get('DNS_NAME') %}
{% set zone = salt.environ.get('DNS_ZONE') %}
{% set ipaddrs = [] %}
{% for host, grains in salt.saltutil.runner(
    'mine.get',
    tgt=instance_id, fun='grains.item').items() %}
{% do ipaddrs.append(grains['ec2:public_ipv4']) %}
{% endfor %}

create_dns_entry_for_{{ instance_id }}:
  boto_route53.present:
    - name: {{ domain }}.{{ zone }}
    - value: {{ ipaddrs|tojson }}
    - record_type: A
    - zone: {{ zone }}
