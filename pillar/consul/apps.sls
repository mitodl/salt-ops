{# Definition of services in the rc-apps and production-apps environments #}
{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set env_settings = salt.file.read(salt.cp.cache_file("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml"))|load_yaml %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}

consul:
  extra_configs:
    defaults:
      recursors:
        - {{ env_settings.environments[ENVIRONMENT].network_prefix }}.0.2
        - 8.8.8.8
