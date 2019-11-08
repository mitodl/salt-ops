{% set encrypt_key = salt.sdb.get('sdb://osenv/CONSUL_ENCRYPT_KEY') %}
{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set lan_nodes = [] %}
{% for host, addr in salt.saltutil.runner(
    'mine.get',
    tgt='consul-' ~ ENVIRONMENT ~ '-*',
    fun='grains.item',
    tgt_type='glob').items() %}
{% do lan_nodes.append('{0}'.format(addr['ec2:local_ipv4'])) %}
{% endfor %}

consul:
  overrides:
    version: 1.4.4
  extra_configs:
    defaults:
      server: {{ 'consul_server' in grains.get('roles') }}
      log_level: WARN
      disable_host_node_id: True
      dns_config:
        allow_stale: True
        node_ttl: 30s
        service_ttl:
          "*": 30s
      {% if encrypt_key %}
      encrypt: {{ encrypt_key }}
      {% else %}
      encrypt: __vault__::secret-operations/global/consul-shared-secret>data>value
      {% endif %}
      retry_join: {{ lan_nodes|tojson }}
      datacenter: {{ ENVIRONMENT }}
