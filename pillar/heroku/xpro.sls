{% set minion_id = salt.grains.get('id', '') %}
{% set environment = minion_id.split('-')[-1] %}

{% set env_dict = {
    'ci': {
      'env_name': 'ci',
      'ga_id': '',
      'release_branch': 'master',
      'log_level': 'DEBUG',
      'OPENEDX_API_BASE_URL': 'https://xpro-qa-sandbox.mitx.mit.edu'
      },
    'rc': {
      'env_name': 'rc',
      'ga_id': '',
      'release_branch': 'release-candidate',
      'log_level': 'INFO',
      'OPENEDX_API_BASE_URL': 'https://xpro-qa.mitx.mit.edu'
      },
    'production': {
      'env_name': 'production',
      'ga_id': '',
      'release_branch': 'release',
      'log_level': 'WARN',
      'OPENEDX_API_BASE_URL': 'https://xpro.mitx.mit.edu'
      }
} %}
{% set env_data = env_dict[environment] %}
{% set business_unit = 'mitxpro' %}

proxy:
  proxytype: heroku

heroku:
  app_name: xpro-{{ env_data.env_name }}
  api_key: __vault__::secret-operations/global/heroku/api_key>data>value
  config_vars:
    AWS_ACCESS_KEY_ID:  __vault__:cache:aws-mitx/creds/read-write-xpro-app-{{ env_data.env_name }}>data>access_key
    AWS_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/read-write-xpro-app-{{ env_data.env_name }}>data>secret_key
    AWS_STORAGE_BUCKET_NAME: 'xpro-{{ env_data.env_name }}'
    GA_TRACKING_ID: {{ env_data.ga_id }}
    MAILGUN_KEY: __vault__::secret-operations/global/mailgun-api-key>data>value
    MAILGUN_FROM_EMAIL: 'MIT xPRO <no-reply@xpro-{{ env_data.env_name }}-mail.odl.mit.edu>'
    MAILGUN_SENDER_DOMAIN: 'odl.mit.edu'
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
    SENTRY_DSN: __vault__::secret-operations/global/xpro/sentry-dsn>data>value
    STATUS_TOKEN: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/django-status-token>data>value
