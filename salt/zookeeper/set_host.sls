# Add /et/hosts entry to match hostname configured
# in zookeeper settings so that process will launch properly
{% set ip_interfaces = salt.grains.get('ip4_interfaces') %}
{% do ip_interfaces.pop('lo') %}
{% for interface, ip in ip_interfaces.items() %}
set_zookeeper_{{ interface }}_host_ip:
  host.present:
    - ip: {{ ip[0] }}
    - names:
        - {{ salt.grains.get('id') }}.zookeeper.service.consul
{% endfor %}
