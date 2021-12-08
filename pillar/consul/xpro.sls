{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set datacenter = ENVIRONMENT.replace("mitxpro", "xpro") %}

consul:
  extra_configs:
    defaults:
      datacenter: {{ datacenter }}
