{% import_yaml salt.cp.cache_file('salt://environment_settings.yml') as env_settings %}
{% set ENVIRONMENT = salt.grains.get('environment', 'rc-apps') %}

nginx-shibboleth:
  secrets:
    key: __vault__::secret-odl-video/{{ ENVIRONMENT }}/shibboleth/sp-key>data>value
    cert: __vault__::secret-odl-video/{{ ENVIRONMENT }}/shibboleth/sp-cert>data>value
