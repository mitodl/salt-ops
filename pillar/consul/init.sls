{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set lan_nodes = ["provider=aws tag_key=consul_env tag_value=" ~ ENVIRONMENT] %}
{% for host, addr in salt.saltutil.runner(
    'mine.get',
    tgt='consul-' ~ ENVIRONMENT ~ '-*',
    fun='grains.item',
    tgt_type='glob').items() %}
{% do lan_nodes.append('{0}'.format(addr['ec2:local_ipv4'])) %}
{% endfor %}
{% set datacenter = salt.grains.get("consul_datacenter") %}

consul:
  products:
    consul: 1.10.1
  extra_configs:
    defaults:
      server: {{ 'consul_server' in grains.get('roles') }}
      log_level: WARN
      disable_host_node_id: True
      dns_config:
        allow_stale: True
        node_ttl: 60s
        service_ttl:
          "*": 30s
      encrypt: __vault__::secret-operations/global/consul-shared-secret>data>value
      retry_join: {{ lan_nodes|tojson }}
      datacenter: {{ datacenter or ENVIRONMENT }}

{% if 'production' in ENVIRONMENT %}
schedule:
  refresh_datadog-{{ ENVIRONMENT }}_credentials:
    days: 5
    function: state.sls
    args:
      - datadog.plugins
{% endif %}
