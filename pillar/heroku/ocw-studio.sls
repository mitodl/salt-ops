{% set minion_id = salt.grains.get('id', '') %}
{% set environment = minion_id.split('-')[-1] %}

{% set env_dict = {
    'ci': {
      'app_name': 'ocw-studio-ci',
      'env_name': 'ci',
      'MAILGUN_SENDER_DOMAIN': 'ocw-ci.mail.odl.mit.edu',
      'OCW_STUDIO_LOG_LEVEL': 'INFO',
      'sentry_log_level': 'WARN',
      'SITE_NAME': 'MIT OCW Studio CI',
      'vault_env_path': 'rc-apps'
      },
    'rc': {
      'app_name': 'ocw-studio-rc',
      'env': 'qa',
      'env_name': 'rc',
      'MAILGUN_SENDER_DOMAIN': 'ocw-rc.mail.odl.mit.edu',
      'OCW_STUDIO_LOG_LEVEL': 'INFO',
      'sentry_log_level': 'WARN',
      'SITE_NAME': 'MIT OCW Studio RC',
      'vault_env_path': 'rc-apps'
      },
    'production': {
      'app_name': 'ocw-studio',
      'env': 'production',
      'env_name': 'production',
      'MAILGUN_SENDER_DOMAIN': 'ocw.mail.odl.mit.edu',
      'OCW_STUDIO_LOG_LEVEL': 'INFO',
      'sentry_log_level': 'WARN',
      'SITE_NAME': 'MIT OCW Studio',
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
    #AWS_ACCESS_KEY_ID:  __vault__:cache:aws-mitx/creds/read-write-delete-ol-ocw-studio-app-{{ env_data.env_name }}>data>access_key
    #AWS_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/read-write-delete-ol-ocw-studio-app-{{ env_data.env_name }}>data>secret_key
    #AWS_STORAGE_BUCKET_NAME: 'ol-ocw-studio-app-{{ env_data.env_name }}'
    {% if env_data.env_name != 'ci' %}
    {% set pg_creds = salt.vault.cached_read('postgres-ocw-studio-applications-{}/creds/ocw_studio'.format(env_data.env), cache_prefix='heroku-ocw-studio') %}
    {% set rds_endpoint = salt.boto_rds.get_endpoint('ocw-studio-db-applications-{}'.format(env_data.env)) %}
    DATABASE_URL: postgres://{{ pg_creds.data.username }}:{{ pg_creds.data.password }}@{{ rds_endpoint }}/ocw_studio
    {% endif %}
    MAILGUN_FROM_EMAIL: 'MIT OCW <no-reply@{{ env_data.MAILGUN_SENDER_DOMAIN }}'
    MAILGUN_KEY: __vault__::secret-operations/global/mailgun-api-key>data>value
    MAILGUN_SENDER_DOMAIN: {{ env_data.MAILGUN_SENDER_DOMAIN }}
    MAILGUN_URL: https://api.mailgun.net/v3/{{ env_data.MAILGUN_SENDER_DOMAIN }}
    OCW_STUDIO_ADMIN_EMAIL: cuddle-bunnies@mit.edu
    OCW_STUDIO_DB_CONN_MAX_AGE: 0
    OCW_STUDIO_DB_DISABLE_SSL: True
    OCW_STUDIO_ENVIRONMENT: {{ env_data.env_name }}
    OCW_STUDIO_LOG_LEVEL: {{ env_data.OCW_STUDIO_LOG_LEVEL }}
    SECRET_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ app }}/{{ environment }}/django-secret-key>data>value
    SENTRY_DSN: __vault__::secret-operations/global/{{ business_unit}}/sentry-dsn>data>value
    SENTRY_LOG_LEVEL: {{ env_data.sentry_log_level }}
    STATUS_TOKEN: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ app }}/{{ environment }}/django-status-token>data>value
