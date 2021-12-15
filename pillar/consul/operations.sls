{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set env_settings = salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml", dest=None)|load_yaml %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set datacenter = ENVIRONMENT %}
{% if ENVIRONMENT == "operations" %}
{% set datacenter = "operations-production" %}
{% endif %}
{% set lan_nodes = ["provider=aws tag_key=consul_env tag_value=" ~ datacenter] %}
{% for host, addr in salt.saltutil.runner(
    'mine.get',
    tgt='consul-' ~ ENVIRONMENT ~ '-*',
    fun='grains.item',
    tgt_type='glob').items() %}
{% do lan_nodes.append('{0}'.format(addr['ec2:local_ipv4'])) %}
{% endfor %}

{% set wan_nodes = [] %}
{% for host, addr in salt.saltutil.runner(
    'mine.get',
    tgt='G@roles:consul_server and not G@environment:{}'.format(ENVIRONMENT),
    fun='grains.item',
    tgt_type='compound').items() %}
{% do wan_nodes.append('{0}'.format(addr['ec2:local_ipv4'])) %}
{% endfor %}

consul:
  extra_configs:
    defaults:
      recursors:
        - {{ env_settings.environments[ENVIRONMENT].network_prefix }}.0.2
        - 1.1.1.1
        - 8.8.8.8
      {% if 'consul_server' in salt.grains.get('roles', []) %}
      retry_join_wan: {{ wan_nodes|tojson }}
      primary_datacenter: {{ datacenter }}
      {% endif %}
      retry_join: {{ lan_nodes|tojson }}
      datacenter: {{ datacenter }}
