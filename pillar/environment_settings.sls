{# This file is for exposing the data in the YAML file via the Pillar system #}
{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
environments:
  {{ env_settings.environments|yaml(False)|indent(2) }}
business_units:
  {{ env_settings.business_units|yaml(False)|indent(2) }}
