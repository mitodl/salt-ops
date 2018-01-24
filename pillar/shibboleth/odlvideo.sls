{% set shibboleth_cert = salt.vault.read('secret-odl-video/{env}/'}

nginx-shibboleth:
  overrides:
    generate_sp_cert: False
  secrets:
    key: |
      {{ salt.vault.read('secret-odl-video/{env}/shibboleth/sp-key'.format(env=ENVIRONMENT).data.value|indent(6) }}
    cert: |
      {{ salt.vault.read('secret-odl-video/{env}/shibboleth/sp-cert'.format(env=ENVIRONMENT).data.value|indent(6) }}
  config:
    shibboleth2:
      SPConfig:
        RequestMapper:
          RequestMap:
            Host:
              name: {{ server_domain_name }}
        ApplicationDefaults:
          entityID: https://{{ server_domain_name }}/shibboleth
