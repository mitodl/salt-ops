{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set lan_nodes = [] %}
{% for host, addr in salt.saltutil.runner(
    'mine.get',
    tgt='G@roles:consul_server and G@environment:{}'.format(ENVIRONMENT),
    fun='grains.item',
    tgt_type='compound').items() %}
{% do lan_nodes.append('{0}'.format(addr['ec2:local_ipv4'])) %}
{% endfor %}

consul:
  overrides:
    version: 1.0.2
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
      encrypt: {{ salt.vault.read('secret-operations/global/consul-shared-secret').data.value }}
      retry_join: {{ lan_nodes }}
      datacenter: {{ ENVIRONMENT }}
