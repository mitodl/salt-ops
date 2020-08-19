{% set env_settings = salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml", dest=None)|load_yaml %}
{% set ENVIRONMENT = salt.grains.get('environment', 'mitx-qa') %}

nginx-shibboleth:
  secrets:
    key: __vault__::secret-residential/{{ ENVIRONMENT }}/mitx-cas/shibboleth/sp-key>data>value
    cert: __vault__::secret-residential/{{ ENVIRONMENT }}/mitx-cas/shibboleth/sp-cert>data>value
