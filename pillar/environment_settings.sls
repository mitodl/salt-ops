{# This file is for exposing the data in the YAML file via the Pillar system #}
{% set env_settings = salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml", dest=None)|load_yaml %}
environments: {{ env_settings.environments|tojson }}
business_units: {{ env_settings.business_units|tojson }}
