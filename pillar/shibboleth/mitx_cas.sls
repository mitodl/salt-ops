{% import_yaml salt.cp.cache_file('salt://environment_settings.yml') as env_settings %}
{% set ENVIRONMENT = salt.grains.get('environment', 'mitx-qa') %}

nginx-shibboleth:
  secrets:
    key: __vault__::secret-residential/{{ ENVIRONMENT }}/mitx-cas/shibboleth/sp-key>data>value
    cert: __vault__::secret-residential/{{ ENVIRONMENT }}/mitx-cas/shibboleth/sp-cert>data>value
