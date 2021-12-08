{# Definition of services in the rc-apps and production-apps environments #}
{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set env_settings = salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml", dest=None)|load_yaml %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set datacenter = "apps-ci" %}
{% if ENVIRONMENT == "rc-apps" %}
{% set datacenter = "apps-qa" %}
{% endif %}
{% if ENVIRONMENT = "production-apps"}
{% set datacenter = "apps-production" %}
{% endif %}

consul:
  extra_configs:
    defaults:
      recursors:
        - {{ env_settings.environments[ENVIRONMENT].network_prefix }}.0.2
        - 8.8.8.8
      datacenter: {{ datacenter }}
