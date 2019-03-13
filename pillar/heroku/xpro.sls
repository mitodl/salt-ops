{% set app_name = 'xpro' %}
{% set environments = ['ci', 'rc', 'production'] %}
{% set status_token = salt.random.get_str(24) %}

proxy:
  proxytype: heroku

heroku:
  {% for env in environments %}
  app_name: {{ app_name }}-{{ env }}
  api_key: __vault__::secret-operations/global/heroku-api-key>data>value
  config_vars:
    AWS_ACCESS_KEY_ID:  __vault__:cache:aws-mitx/creds/xpro-{{ env }}>data>access_key
    AWS_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/xpro-{{ env }}>data>secret_key
    AWS_STORAGE_BUCKET_NAME: 'xpro-{{ env }}'
    MAILGUN_URL: 'https://api.mailgun.net/v3/xpro-{{ env }}-mail.odl.mit.edu'
    MAILGUN_KEY: __vault__::secret-operations/global/mailgun-api-key>data>value
    MAILGUN_FROM_EMAIL: 'MIT xPRO <no-reply@xpro-{{ env }}-mail.odl.mit.edu>'
    MITXPRO_ADMIN_EMAIL: 'cuddle-bunnies@mit.edu'
    MITXPRO_DB_CONN_MAX_AGE: 0
    MITXPRO_DB_DISABLE_SSL: True
    MITXPRO_EMAIL_HOST: __vault__::secret-operations/global/mit-smtp>data>relay_host
    MITXPRO_EMAIL_PASSWORD: __vault__::secret-operations/global/mit-smtp>data>relay_password
    MITXPRO_EMAIL_PORT: 587
    MITXPRO_EMAIL_TLS: True
    MITXPRO_EMAIL_USER: __vault__::secret-operations/global/mit-smtp>data>relay_username
    MITXPRO_ENVIRONMENT: ci
    MITXPRO_FROM_EMAIL: 'MIT xPro <xpro-{{ env }}-support@mit.edu>'
    MITXPRO_LOG_LEVEL: INFO
    MITXPRO_SECURE_SSL_REDIRECT: True
    MITXPRO_SUPPORT_EMAIL: 'xpro-{{ env }}-support@mit.edu'
    MITXPRO_USE_S3: True
    NODE_MODULES_CACHE: False
    PGBOUNCER_DEFAULT_POOL_SIZE: 50
    PGBOUNCER_MIN_POOL_SIZE: 5
    SENTRY_DSN: __vault__::secret-operations/global/xpro/sentry-dsn>data>value
    STATUS_TOKEN: {{ status_token }}
  {% endfor %}
