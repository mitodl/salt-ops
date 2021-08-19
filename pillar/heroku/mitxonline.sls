{% set minion_id = salt.grains.get('id', '') %}
{% set environment = minion_id.split('-')[-1] %}
{% set rds_endpoint = salt.boto_rds.get_endpoint('mitxonline-production-app-db') %}

{% set env_dict = {
    'rc': {
      'app_name': 'mitxonline-rc',
      'env_name': 'rc',
      'env_stage': 'qa'
      'GOOGLE_TRACKING_ID': '',
      'GOOGLE_TAG_MANAGER_ID': '',
      'release_branch': 'release-candidate',
      'app_log_level': 'INFO',
      'sentry_log_level': 'ERROR',
      'logout_redirect_url': 'https://lms-qa.mitxonline.mit.edu/logout',
      'OPENEDX_API_BASE_URL': 'https://lms-qa.mitxonline.mit.edu',
      'openedx_environment': 'mitxonline-qa',
      'MAILGUN_FROM_EMAIL': 'MITx Online <no-reply@mitxonline-rc-mail.mitxonline.mit.edu>',
      'MAILGUN_SENDER_DOMAIN': 'mitxonline-rc-mail.mitxonline.mit.edu',
      'MITXONLINE_BASE_URL': 'https://mitxonline-rc.mitxonline.mit.edu',
      'MITXONLINE_SECURE_SSL_HOST': 'mitxonline-rc.mitxonline.mit.edu',
      'vault_env_path': 'rc-apps',
      },
    'production': {
      'app_name': 'mitxonline-production',
      'env_name': 'production',
      'env_stage': 'production',
      'GOOGLE_TRACKING_ID': '',
      'GOOGLE_TAG_MANAGER_ID': '',
      'release_branch': 'release',
      'app_log_level': 'INFO',
      'sentry_log_level': 'ERROR',
      'logout_redirect_url': 'https://lms.mitxonline.mit.edu/logout',
      'OPENEDX_API_BASE_URL': 'https://lms.mitxonline.mit.edu',
      'openedx_environment': 'mitxonline-production',
      'MAILGUN_FROM_EMAIL': 'MITx Online <no-reply@mail.mitxonline.mit.edu>',
      'MAILGUN_SENDER_DOMAIN': 'mail.mitxonline.mit.edu',
      'MITXONLINE_BASE_URL': 'https://mitxonline.mit.edu',
      'MITXONLINE_SECURE_SSL_HOST': 'mitxonline.mit.edu',
      'vault_env_path': 'production-apps',
      }
} %}
{% set env_data = env_dict[environment] %}
{% set business_unit = 'mitxonline' %}

proxy:
  proxytype: heroku

heroku:
  app_name: {{ env_data.app_name }}
  api_key: __vault__::secret-{{ business_unit }}/heroku/api_key>data>value
  config_vars:
    AWS_ACCESS_KEY_ID:  __vault__:cache:aws-mitx/creds/mitxonline>data>access_key
    AWS_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/mitxonline>data>secret_key
    AWS_STORAGE_BUCKET_NAME: 'ol-mitxonline-app-{{ env_data.env_stage}}'
    {% if env_data.env_name == 'production' %}
    {% set pg_creds = salt.vault.cached_read('postgres-mitxonline/creds/mitxonline', cache_prefix='heroku-mitxonline') %}
    DATABASE_URL: postgres://{{ pg_creds.data.username }}:{{ pg_creds.data.password }}@{{ rds_endpoint }}/mitxonline
    HIREFIRE_TOKEN: __vault__::secret-{{ business_unit }}/production-apps/hirefire_token>data>value
    {% endif %}
    GA_TRACKING_ID: {{ env_data.GOOGLE_TRACKING_ID }}
    GTM_TRACKING_ID: {{ env_data.GOOGLE_TAG_MANAGER_ID }}
    LOGOUT_REDIRECT_URL: {{ env_data.logout_redirect_url }}
    MAILGUN_KEY: __vault__::secret-operations/global/mailgun-api-key>data>value
    MAILGUN_FROM_EMAIL: {{ env_data.MAILGUN_FROM_EMAIL }}
    MAILGUN_SENDER_DOMAIN: {{ env_data.MAILGUN_SENDER_DOMAIN }}
    MITX_ONLINE_ADMIN_EMAIL: 'cuddle-bunnies@mit.edu'
    MITX_ONLINE_BASE_URL: {{ env_data.MITXONLINE_BASE_URL }}
    MITX_ONLINE_DB_CONN_MAX_AGE: 0
    MITX_ONLINE_DB_DISABLE_SSL: True    # pgbouncer buildpack uses stunnel to handle encryption
    MITX_ONLINE_ENVIRONMENT: {{ env_data.env_name }}
    MITX_ONLINE_FROM_EMAIL: 'MITx Online <support@mitxonline.mit.edu>'
    MITX_ONLINE_LOG_LEVEL: {{ env_data.app_log_level }}
    MITX_ONLINE_OAUTH_PROVIDER: 'mitxonline-oauth2'
    MITX_ONLINE_REGISTRATION_ACCESS_TOKEN:  __vault__:gen_if_missing:secret-{{ business_unit }}/{{ env_data.openedx_environment }}/mitxonline-registration-access-token>data>value
    MITX_ONLINE_REPLY_TO_ADDRESS: 'MITx Online <support@mitxonline.mit.edu>'
    MITX_ONLINE_SECURE_SSL_REDIRECT: True
    MITX_ONLINE_SECURE_SSL_HOST: {{ env_data.MITXONLINE_SECURE_SSL_HOST }}
    MITX_ONLINE_USE_S3: True
    NODE_MODULES_CACHE: False
    OPENEDX_API_BASE_URL: {{ env_data.OPENEDX_API_BASE_URL}}
    OPENEDX_API_CLIENT_ID: __vault__::secret-{{ business_unit }}/{{ environment }}/openedx-api-client>data>client-id
    OPENEDX_API_CLIENT_SECRET: __vault__::secret-{{ business_unit }}/{{ environment }}/openedx-api-client>data>client-secret
    OPENEDX_API_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ env_data.openedx_environment }}/edx-api-key>data>value
    OPENEDX_SERVICE_WORKER_API_TOKEN: __vault__::secret-{{ business_unit }}/{{ environment }}/openedx-service-worker-api-token>data>value
    OPENEDX_SERVICE_WORKER_USERNAME: mitxonline-service-worker-api
    PGBOUNCER_DEFAULT_POOL_SIZE: 50
    PGBOUNCER_MIN_POOL_SIZE: 5
    RECAPTCHA_SITE_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/recaptcha-keys>data>site_key
    RECAPTCHA_SECRET_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/recaptcha-keys>data>secret_key
    SECRET_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/django-secret-key>data>value
    SENTRY_DSN: __vault__::secret-operations/global/mitxonline/sentry-dsn>data>value
    SENTRY_LOG_LEVEL: {{ env_data.sentry_log_level }}
    SITE_NAME: "MITx Online"
    STATUS_TOKEN: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/django-status-token>data>value
    USE_X_FORWARDED_HOST: True

schedule:
  refresh_{{ env_data.app_name }}_configs:
    days: 5
    function: state.sls
    args:
      - heroku.update_heroku_config
