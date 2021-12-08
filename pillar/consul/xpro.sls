{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set datacenter = ENVIRONMENT.replace("mitxpro", "xpro") %}
{% set lan_nodes = ["provider=aws tag_key=consul_env tag_value=" ~ datacenter] %}
{% for host, addr in salt.saltutil.runner(
    'mine.get',
    tgt='consul-' ~ ENVIRONMENT ~ '-*',
    fun='grains.item',
    tgt_type='glob').items() %}
{% do lan_nodes.append('{0}'.format(addr['ec2:local_ipv4'])) %}
{% endfor %}

consul:
  extra_configs:
    defaults:
      datacenter: {{ datacenter }}
      retry_join: {{ lan_nodes|tojson }}
