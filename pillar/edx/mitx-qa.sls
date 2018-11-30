edx:
  gitreload:
    basic_auth:
      username: mitx
      password: __vault__::secret-residential/mitx-qa/gitreload>data>value
  ansible_vars:
    EDXAPP_CAS_SERVER_URL: 'https://auth.mitx.mit.edu/cas'
    EDXAPP_LMS_ENV_EXTRA:
      FEATURES:
        ENABLE_COMBINED_LOGIN_REGISTRATION: true
        ENABLE_THIRD_PARTY_AUTH: true
    EDXAPP_LMS_AUTH_EXTRA:
      SOCIAL_AUTH_SAML_SP_PUBLIC_CERT: __vault__::secret-residential/mitx-qa/saml-sp-cert>data>value
      SOCIAL_AUTH_SAML_SP_PRIVATE_KEY: __vault__::secret-residential/mitx-qa/saml-sp-cert>data>key
