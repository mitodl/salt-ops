{# This file is for exposing the data in the YAML file via the Pillar system #}
{% import_yaml salt.cp.cache_file("salt://environment_settings.yml") as env_settings %}
environments: {{ env_settings.environments }}
business_units: {{ env_settings.business_units }}
