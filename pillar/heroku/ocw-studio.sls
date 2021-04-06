{% set minion_id = salt.grains.get('id', '') %}
{% set environment = minion_id.split('-')[-1] %}

{% set env_dict = {
    'ci': {
      'app_name': 'ocw-studio-ci',
      'env': 'qa',
      'env_name': 'ci',
      'GTM_ACCOUNT_ID': 'GTM-5JZ7X78',
      'MAILGUN_SENDER_DOMAIN': 'ocw-ci.mail.odl.mit.edu',
      'OCW_STUDIO_BASE_URL': 'https://ocw-studio-ci.odl.mit.edu/',
      'OCW_STUDIO_LOG_LEVEL': 'INFO',
      'OCW_STUDIO_SUPPORT_EMAIL': 'ocw-studio-ci-support@mit.edu',
      'sentry_log_level': 'WARN',
      'SITE_NAME': 'MIT OCW Studio CI',
      'SOCIAL_AUTH_SAML_SP_ENTITY_ID': 'https://ocw-studio-ci.odl.mit.edu/saml/metadata',
      'vault_env_path': 'rc-apps'
      },
    'rc': {
      'app_name': 'ocw-studio-rc',
      'env': 'qa',
      'env_name': 'rc',
      'GTM_ACCOUNT_ID': 'GTM-57BZ8PN',
      'MAILGUN_SENDER_DOMAIN': 'ocw-rc.mail.odl.mit.edu',
      'OCW_STUDIO_BASE_URL': 'https://ocw-studio-rc.odl.mit.edu/',
      'OCW_STUDIO_LOG_LEVEL': 'INFO',
      'OCW_STUDIO_SUPPORT_EMAIL': 'ocw-studio-rc-support@mit.edu',
      'sentry_log_level': 'WARN',
      'SITE_NAME': 'MIT OCW Studio RC',
      'SOCIAL_AUTH_SAML_SP_ENTITY_ID': 'https://ocw-studio-rc.odl.mit.edu/saml/metadata',
      'vault_env_path': 'rc-apps'
      },
    'production': {
      'app_name': 'ocw-studio',
      'env': 'production',
      'env_name': 'production',
      'GTM_ACCOUNT_ID': 'GTM-MQCSLSQ',
      'MAILGUN_SENDER_DOMAIN': 'ocw.mail.odl.mit.edu',
      'OCW_STUDIO_BASE_URL': 'https://ocw-studio.odl.mit.edu/',
      'OCW_STUDIO_LOG_LEVEL': 'INFO',
      'OCW_STUDIO_SUPPORT_EMAIL': 'ocw-studio-support@mit.edu',
      'sentry_log_level': 'WARN',
      'SITE_NAME': 'MIT OCW Studio',
      'SOCIAL_AUTH_SAML_SP_ENTITY_ID': 'https://ocw-studio.odl.mit.edu/saml/metadata',
      'vault_env_path': 'production-apps',
      }
} %}
{% set env_data = env_dict[environment] %}
{% set business_unit = 'open-courseware' %}
{% set app = 'ocw-studio' %}

proxy:
  proxytype: heroku

heroku:
  app_name: {{ env_data.app_name }}
  api_key: __vault__::secret-operations/global/heroku/api_key>data>value
  config_vars:
    ALLOWED_HOSTS: '["*"]'
    AWS_ACCESS_KEY_ID:  __vault__:cache:aws-mitx/creds/ocw-studio-app-{{ env_data.env }}>data>access_key
    AWS_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/ocw-studio-app-{{ env_data.env }}>data>secret_key
    AWS_STORAGE_BUCKET_NAME: 'ol-ocw-studio-app-{{ env_data.env }}'
    {% if env_data.env_name != 'ci' %}
    {% set pg_creds = salt.vault.cached_read('postgres-ocw-studio-applications-{}/creds/app'.format(env_data.env), cache_prefix='heroku-ocw-studio-' ~ env_data.env) %}
    {% set rds_endpoint = salt.boto_rds.get_endpoint('ocw-studio-db-applications-{}'.format(env_data.env)) %}
    DATABASE_URL: postgres://{{ pg_creds.data.username }}:{{ pg_creds.data.password }}@{{ rds_endpoint }}/ocw_studio
    {% endif %}
    GTM_ACCOUNT_ID: {{ env_data.GTM_ACCOUNT_ID }}
    MAILGUN_FROM_EMAIL: 'MIT OCW <no-reply@{{ env_data.MAILGUN_SENDER_DOMAIN }}'
    MAILGUN_KEY: __vault__::secret-operations/global/mailgun-api-key>data>value
    MAILGUN_SENDER_DOMAIN: {{ env_data.MAILGUN_SENDER_DOMAIN }}
    MAILGUN_URL: https://api.mailgun.net/v3/{{ env_data.MAILGUN_SENDER_DOMAIN }}
    OCW_STUDIO_ADMIN_EMAIL: cuddle-bunnies@mit.edu
    OCW_STUDIO_BASE_URL: {{ env_data.OCW_STUDIO_BASE_URL }}
    OCW_STUDIO_DB_CONN_MAX_AGE: 0
    OCW_STUDIO_DB_DISABLE_SSL: True
    OCW_STUDIO_ENVIRONMENT: {{ env_data.env_name }}
    OCW_STUDIO_LOG_LEVEL: {{ env_data.OCW_STUDIO_LOG_LEVEL }}
    OCW_STUDIO_SUPPORT_EMAIL: {{ env_data.OCW_STUDIO_SUPPORT_EMAIL }}
    OCW_STUDIO_USE_S3: True
    SECRET_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ app }}/{{ environment }}/django-secret-key>data>value
    SENTRY_DSN: __vault__::secret-operations/global/{{ business_unit}}/sentry-dsn>data>value
    SENTRY_LOG_LEVEL: {{ env_data.sentry_log_level }}
    SOCIAL_AUTH_SAML_CONTACT_NAME: Open Learning Support
    SOCIAL_AUTH_SAML_IDP_ATTRIBUTE_EMAIL: urn:oid:0.9.2342.19200300.100.1.3
    SOCIAL_AUTH_SAML_IDP_ATTRIBUTE_NAME: urn:oid:2.16.840.1.113730.3.1.241
    SOCIAL_AUTH_SAML_IDP_ATTRIBUTE_PERM_ID: urn:oid:1.3.6.1.4.1.5923.1.1.1.6
    SOCIAL_AUTH_SAML_IDP_ENTITY_ID: https://idp.mit.edu/shibboleth
    SOCIAL_AUTH_SAML_IDP_URL: https://idp.mit.edu/idp/profile/SAML2/Redirect/SSO
    SOCIAL_AUTH_SAML_LOGIN_URL: https://idp.mit.edu/idp/profile/SAML2/Redirect/SSO
    SOCIAL_AUTH_SAML_IDP_X509: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/saml>data>idp_x509
    SOCIAL_AUTH_SAML_ORG_DISPLAYNAME: MIT Open Learning
    SOCIAL_AUTH_SAML_SECURITY_ENCRYPTED: True
    SOCIAL_AUTH_SAML_SP_ENTITY_ID: {{ env_data.SOCIAL_AUTH_SAML_SP_ENTITY_ID }}
    SOCIAL_AUTH_SAML_SP_PRIVATE_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/saml>data>private_key
    SOCIAL_AUTH_SAML_SP_PUBLIC_CERT: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/saml>data>public_cert
    STATUS_TOKEN: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ app }}/{{ environment }}/django-status-token>data>value
    USE_X_FORWARDED_PORT: True
