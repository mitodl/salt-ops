{% set minion_id = salt.grains.get('id', '') %}
{% set environment = minion_id.split('-')[-1] %}
{% set rds_endpoint = salt.boto_rds.get_endpoint('production-apps-rds-postgres-mitxpro') %}

{% set env_dict = {
    'ci': {
      'env_name': 'ci',
      'ga_id': '',
      'release_branch': 'master',
      'log_level': 'DEBUG',
      'logout_redirect_url': 'https://xpro-ci.odl.mit.edu',
      'OPENEDX_API_BASE_URL': 'https://xpro-qa-sandbox.mitx.mit.edu',
      'CYBERSOURCE_SECURE_ACCEPTANCE_URL': 'https://testsecureacceptance.cybersource.com/pay'
      },
    'rc': {
      'env_name': 'rc',
      'ga_id': '',
      'release_branch': 'release-candidate',
      'log_level': 'INFO',
      'logout_redirect_url': 'https://xpro-ci.odl.mit.edu',
      'OPENEDX_API_BASE_URL': 'https://xpro-qa.mitx.mit.edu',
      'CYBERSOURCE_SECURE_ACCEPTANCE_URL': 'https://testsecureacceptance.cybersource.com/pay'
      },
    'production': {
      'env_name': 'production',
      'ga_id': '',
      'release_branch': 'release',
      'log_level': 'WARN',
      'logout_redirect_url': 'https://xpro.odl.mit.edu',
      'OPENEDX_API_BASE_URL': 'https://xpro.mitx.mit.edu',
      'CYBERSOURCE_SECURE_ACCEPTANCE_URL': 'https://secureacceptance.cybersource.com/pay'
      }
} %}
{% set env_data = env_dict[environment] %}
{% set business_unit = 'mitxpro' %}
{% set pg_creds = salt.vault.cached_read('postgres-production-apps-mitxpro/creds/mitxpro', cache_prefix='heroku-mitxpro') %}
{% set cybersource_creds = salt.vault.read('secret-' ~ business_unit ~ '/' ~ env_data.env_name ~ '/cybersource') %}

proxy:
  proxytype: heroku

heroku:
  app_name: xpro-{{ env_data.env_name }}
  api_key: __vault__::secret-operations/global/heroku/api_key>data>value
  config_vars:
    AWS_ACCESS_KEY_ID:  __vault__:cache:aws-mitx/creds/read-write-xpro-app-{{ env_data.env_name }}>data>access_key
    AWS_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/read-write-xpro-app-{{ env_data.env_name }}>data>secret_key
    AWS_STORAGE_BUCKET_NAME: 'xpro-app-{{ env_data.env_name }}'
    CYBERSOURCE_ACCESS_KEY: {{ cybersource_creds.data.access_key }}
    CYBERSOURCE_PROFILE_ID: {{ cybersource_creds.data.profile_id }}
    CYBERSOURCE_REFERENCE_PREFIX: xpro-{{ env_data.env_name }}
    CYBERSOURCE_SECURE_ACCEPTANCE_URL: {{ env_data.CYBERSOURCE_SECURE_ACCEPTANCE_URL}}
    CYBERSOURCE_SECURITY_KEY: {{ cybersource_creds.data.security_key }}
    {% if env_data.env_name == 'production' %}
    DATABASE_URL: postgres://{{ pg_creds.data.username }}:{{ pg_creds.data.password }}@{{ rds_endpoint }}/mitxproproduction
    {% endif %}
    GA_TRACKING_ID: {{ env_data.ga_id }}
    LOGOUT_REDIRECT_URL: {{ env_data.logout_redirect_url }}
    MAILGUN_KEY: __vault__::secret-operations/global/mailgun-api-key>data>value
    MAILGUN_FROM_EMAIL: 'MIT xPRO <no-reply@xpro-{{ env_data.env_name }}-mail.odl.mit.edu>'
    MAILGUN_SENDER_DOMAIN: 'xpro-{{ env_data.env_name }}-mail.odl.mit.edu'
    MITXPRO_ADMIN_EMAIL: 'cuddle-bunnies@mit.edu'
    MITXPRO_BASE_URL: 'https://xpro-{{ env_data.env_name}}.odl.mit.edu'
    MITXPRO_DB_CONN_MAX_AGE: 0
    MITXPRO_DB_DISABLE_SSL: True    # pgbouncer buildpack uses stunnel to handle encryption
    MITXPRO_EMAIL_HOST: __vault__::secret-operations/global/mit-smtp>data>relay_host
    MITXPRO_EMAIL_PASSWORD: __vault__::secret-operations/global/mit-smtp>data>relay_password
    MITXPRO_EMAIL_PORT: 587
    MITXPRO_EMAIL_TLS: True
    MITXPRO_EMAIL_USER: __vault__::secret-operations/global/mit-smtp>data>relay_username
    MITXPRO_ENVIRONMENT: {{ env_data.env_name }}
    MITXPRO_FROM_EMAIL: 'MIT xPro <xpro-{{ env_data.env_name }}-support@mit.edu>'
    MITXPRO_LOG_LEVEL: {{ env_data.log_level }}
    MITXPRO_OAUTH_PROVIDER: 'mitxpro-oauth2'
    MITXPRO_REGISTRATION_ACCESS_TOKEN:  __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/xpro-registration-access-token>data>value
    MITXPRO_SECURE_SSL_REDIRECT: True
    MITXPRO_SUPPORT_EMAIL: 'xpro-{{ env_data.env_name }}-support@mit.edu'
    MITXPRO_USE_S3: True
    NODE_MODULES_CACHE: False
    OPENEDX_API_BASE_URL: {{ env_data.OPENEDX_API_BASE_URL}}
    OPENEDX_API_CLIENT_ID: __vault__::secret-{{ business_unit }}/{{ environment }}/openedx-api-client>data>client-id
    OPENEDX_API_CLIENT_SECRET: __vault__::secret-{{ business_unit }}/{{ environment }}/openedx-api-client>data>client-secret
    OPENEDX_OAUTH_APP_NAME: 'edx-oauth-app'
    PGBOUNCER_DEFAULT_POOL_SIZE: 50
    PGBOUNCER_MIN_POOL_SIZE: 5
    SECRET_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/django-secret-key>data>value
    SENTRY_DSN: __vault__::secret-operations/global/xpro/sentry-dsn>data>value
    SENTRY_LOG_LEVEL: {{ env_data.log_level }}
    STATUS_TOKEN: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/django-status-token>data>value
