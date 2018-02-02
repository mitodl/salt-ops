#!jinja|yaml
{% set SAML_SP_CERT = salt.vault.read('secret-residential/mitx-qa/saml-sp-cert') %}

edx:
  gitreload:
    basic_auth:
      username: mitx
      password: {{ salt.vault.read('secret-residential/mitx-qa/gitreload').data.value }}
  ansible_vars:
    EDXAPP_LOG_LEVEL: 'DEBUG'
    EDXAPP_CAS_SERVER_URL: 'https://auth.mitx.mit.edu/cas'
    EDXAPP_LMS_ENV_EXTRA:
      SOCIAL_AUTH_SAML_SP_PUBLIC_CERT: |
        {{ SAML_SP_CERT.data.value|indent(8) }}
      SOCIAL_AUTH_SAML_SP_PRIVATE_KEY: |
        {{ SAML_SP_CERT.data.key|indent(8) }}
      FEATURES:
        ENABLE_COMBINED_LOGIN_REGISTRATION: true
        ENABLE_THIRD_PARTY_AUTH: true
        ENABLE_UNICODE_USERNAME: true
