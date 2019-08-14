{% set ENVIRONMENT = salt.grains.get('environment', 'operations') %}

nginx-shibboleth:
  secrets:
    key: __vault__::secret-operations/{{ ENVIRONMENT }}/redash/shibboleth>data>sp_key
    cert: __vault__::secret-operations/{{ ENVIRONMENT }}/redash/shibboleth>data>sp_cert
