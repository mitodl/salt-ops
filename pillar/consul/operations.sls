{% set ENVIRONMENT = 'operations' %}
{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}

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
        - 8.8.8.8
    {% if 'consul_server' in salt.grains.get('roles', []) %}
      retry_join_wan: {{ wan_nodes }}
    {% endif %}
