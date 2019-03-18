{% set app_name = 'xpro' %}
{% set status_token = __vault__:gen_if_missing:secret-operations/global/xpro/django-status-token>data>value %}
{% set env_dict = {
    'ci': {
      'env_name': 'ci',
      'ga_id': '',
      'release_branch': 'master',
      'log_level': 'DEBUG'
      },
    'rc': {
      'env_name': 'rc',
      'ga_id': '',
      'release_branch': 'release-candidate',
      'log_level': 'INFO'
      },
    'production': {
      'env_name': 'production',
      'ga_id': '',
      'release_branch': 'release',
      'log_level': 'WARN'
      }
} %}

proxy:
  proxytype: heroku

heroku:
  {% for env_data in env_dict %}
  app_name: {{ app_name }}-{{ env_data.env_name }}
  api_key: __vault__::secret-operations/global/heroku-api-key>data>value
  config_vars:
    AWS_ACCESS_KEY_ID:  __vault__:cache:aws-mitx/creds/xpro-{{ env_data.env_name }}>data>access_key
    AWS_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/xpro-{{ env_data.env_name }}>data>secret_key
    AWS_STORAGE_BUCKET_NAME: 'xpro-{{ env_data.env_name }}'
    GA_TRACKING_ID: {{ env_data.ga_id }}
    MAILGUN_URL: 'https://api.mailgun.net/v3/xpro-{{ env_data.env_name }}-mail.odl.mit.edu'
    MAILGUN_KEY: __vault__::secret-operations/global/mailgun-api-key>data>value
    MAILGUN_FROM_EMAIL: 'MIT xPRO <no-reply@xpro-{{ env_data.env_name }}-mail.odl.mit.edu>'
    MITXPRO_ADMIN_EMAIL: 'cuddle-bunnies@mit.edu'
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
    MITXPRO_SECURE_SSL_REDIRECT: True
    MITXPRO_SUPPORT_EMAIL: 'xpro-{{ env_data.env_name }}-support@mit.edu'
    MITXPRO_USE_S3: True
    NODE_MODULES_CACHE: False
    PGBOUNCER_DEFAULT_POOL_SIZE: 50
    PGBOUNCER_MIN_POOL_SIZE: 5
    SENTRY_DSN: __vault__::secret-operations/global/xpro/sentry-dsn>data>value
    STATUS_TOKEN: {{ status_token }}
  {% endfor %}
