{% set ENVIRONMENT = salt.grains.get('environment') %}

consul:
  overrides:
    version: 1.8.3
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
      encrypt: __vault__::secret-operations/global/consul-shared-secret>data>value
      retry_join:
        - "provider=aws tag_key=consul_env tag_value={{ ENVIRONMENT }}"
      datacenter: {{ ENVIRONMENT }}

{% if 'production' in ENVIRONMENT %}
schedule:
  refresh_datadog-{{ ENVIRONMENT }}_credentials:
    days: 5
    function: state.sls
    args:
      - datadog.plugins
{% endif %}
