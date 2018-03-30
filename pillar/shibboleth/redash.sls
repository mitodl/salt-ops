{% set ENVIRONMENT = salt.grains.get('environment', 'operations') %}

nginx-shibboleth:
  secrets:
    key: |
      {{ salt.vault.read('secret-operations/{env}/redash/shibboleth-sp-key'.format(env=ENVIRONMENT)).data.value|replace('\\n', '\n')|indent(6) }}
    cert: |
      {{ salt.vault.read('secret-operations/{env}/redash/shibboleth-sp-cert'.format(env=ENVIRONMENT)).data.value|replace('\\n', '\n')|indent(6) }}
