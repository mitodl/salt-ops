{% set ENVIRONMENT = salt.grains.get('environment', 'operations') %}

nginx-shibboleth:
  secrets:
    key: __vault__::secret-odl-video/{{ ENVIRONMENT }}/shibboleth/sp-key>data>value
    cert: __vault__::secret-odl-video/{{ ENVIRONMENT }}/shibboleth/sp-cert>data>value
