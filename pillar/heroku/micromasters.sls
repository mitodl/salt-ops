{% set minion_id = salt.grains.get('id', '') %}
{% set environment = minion_id.split('-')[-1] %}
{% set rds_endpoint = salt.boto_rds.get_endpoint('micromasters-db') %}

{% set env_dict = {
    'ci': {
      'app_name': 'micromasters-ci',
      'CLOUDFRONT_DIST': '',
      'ELASTICSEARCH_INDEX': 'micromasters-ci',
      'env_name': 'ci',
      'FEATURE_EXAMS_CARD_ENABLED': False,
      'GA_TRACKING_ID': 'UA-5145472-14',
      'GTM_CONTAINER_ID': 'GTM-NB27R8L',
      'MAILGUN_FROM_EMAIL': 'no-reply@micromasters-rc-mail.odl.mit.edu',
      'MAILGUN_URL': 'https://api.mailgun.net/v3/micromasters-rc-mail.odl.mit.edu',
      'MICROMASTERS_CORS_ORIGIN_WHITELIST': "['discussions-ci.odl.mit.edu']",
      'MICROMASTERS_LOG_LEVEL': 'DEBUG',
      'MIDDLEWARE_FEATURE_FLAG_QS_PREFIX': '',
      'OPEN_DISCUSSIONS_API_USERNAME': 'od_mm_ci_api',
      'OPEN_DISCUSSIONS_BASE_URL': 'https://discussions-ci.odl.mit.edu/',
      'OPEN_DISCUSSIONS_COOKIE_DOMAIN': 'odl.mit.edu',
      'OPEN_DISCUSSIONS_COOKIE_NAME': 'discussionsci',
      'PGBOUNCER_DEFAULT_POOL_SIZE': 100,
      'PGBOUNCER_MAX_CLIENT_CONN': 1000,
      'vault_env_path': 'rc-apps'
      },
    'rc': {
      'app_name': 'micromasters-rc',
      'CLOUDFRONT_DIST': 'd3o95baofem9lo',
      'ELASTICSEARCH_INDEX': 'micromasters-rc',
      'env_name': 'rc',
      'FEATURE_EXAMS_CARD_ENABLED': False,
      'GA_TRACKING_ID': 'UA-5145472-14',
      'GTM_CONTAINER_ID': 'GTM-NB27R8L',
      'MAILGUN_FROM_EMAIL': 'no-reply@micromasters-rc-mail.odl.mit.edu',
      'MAILGUN_URL': 'https://api.mailgun.net/v3/micromasters-rc-mail.odl.mit.edu',
      'MICROMASTERS_CORS_ORIGIN_WHITELIST': "['discussions-rc.odl.mit.edu']",
      'MICROMASTERS_LOG_LEVEL': 'DEBUG',
      'MIDDLEWARE_FEATURE_FLAG_QS_PREFIX': 'BGA',
      'OPEN_DISCUSSIONS_API_USERNAME': 'od_mm_rc_api',
      'OPEN_DISCUSSIONS_BASE_URL': 'https://discussions-rc.odl.mit.edu/',
      'OPEN_DISCUSSIONS_COOKIE_DOMAIN': 'odl.mit.edu',
      'OPEN_DISCUSSIONS_COOKIE_NAME': 'discussionsrc',
      'PGBOUNCER_DEFAULT_POOL_SIZE': 100,
      'PGBOUNCER_MAX_CLIENT_CONN': 1000,
      'vault_env_path': 'rc-apps'
      },
    'production': {
      'app_name': 'micromasters-production',
      'CLOUDFRONT_DIST': 'do5zh7b0lqdye',
      'ELASTICSEARCH_INDEX': 'micromasters',
      'env_name': 'production',
      'FEATURE_EXAMS_CARD_ENABLED': True,
      'GA_TRACKING_ID': 'UA-5145472-10',
      'GTM_CONTAINER_ID': 'GTM-NB27R8L',
      'MAILGUN_FROM_EMAIL': 'no-reply@micromasters.odl.mit.edu',
      'MAILGUN_URL': 'https://api.mailgun.net/v3/micromasters.odl.mit.edu',
      'MICROMASTERS_CORS_ORIGIN_WHITELIST': "['discussions.odl.mit.edu','odl.mit.edu']",
      'MICROMASTERS_LOG_LEVEL': 'INFO',
      'MIDDLEWARE_FEATURE_FLAG_QS_PREFIX': 'XIQ',
      'OPEN_DISCUSSIONS_API_USERNAME': 'od_mm_prod_api',
      'OPEN_DISCUSSIONS_BASE_URL': 'https://open.mit.edu',
      'OPEN_DISCUSSIONS_COOKIE_DOMAIN': 'mit.edu',
      'OPEN_DISCUSSIONS_COOKIE_NAME': 'discussionsprod',
      'PGBOUNCER_DEFAULT_POOL_SIZE': 20,
      'PGBOUNCER_MAX_CLIENT_CONN': 500,
      'vault_env_path': 'production-apps'
      }
} %}
{% set env_data = env_dict[environment] %}
{% set business_unit = 'micromasters' %}
{% set cybersource_creds = salt.vault.read('secret-' ~ business_unit ~ '/' ~ env_data.vault_env_path ~ '/cybersource').data %}
{% set exams_audit = salt.vault.read('secret-' ~ business_unit ~ '/' ~ env_data.vault_env_path ~ '/exams_audit').data %}
{% set exams_sftp = salt.vault.read('secret-' ~ business_unit ~ '/' ~ env_data.vault_env_path ~ '/exams_sftp').data %}

proxy:
  proxytype: heroku

heroku:
  app_name: {{ env_data.app_name }}
  api_key: __vault__::secret-operations/global/heroku/api_key>data>value
  config_vars:
    ALLOWED_HOSTS: '[*]'
    AWS_ACCESS_KEY_ID: __vault__:cache:aws-mitx/creds/read-write-delete-{{ business_unit }}-app-{{ env_data.env_name }}>data>access_key
    AWS_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/read-write-delete-{{ business_unit }}-app-{{ env_data.env_name }}>data>secret_key
    AWS_STORAGE_BUCKET_NAME: odl-{{ business_unit}}-{{ env_data.env_name }}
    BATCH_UPDATE_RATE_LIMIT: '2/m'
    CLOUDFRONT_DIST: {{ env_data.CLOUDFRONT_DIST }}
    CYBERSOURCE_ACCESS_KEY: {{ cybersource_creds.access_key }}
    CYBERSOURCE_PROFILE_ID: {{ cybersource_creds.profile_id }}
    CYBERSOURCE_REFERENCE_PREFIX: {{ env_data.CYBERSOURCE_REFERENCE_PREFIX }}
    CYBERSOURCE_SECURE_ACCEPTANCE_URL: {{ env_data.CYBERSOURCE_SECURE_ACCEPTANCE_URL}}
    CYBERSOURCE_SECURITY_KEY: {{ cybersource_creds.security_key }}
    {% if env_data.env_name == 'production' %}
    {% set pg_creds = salt.vault.cached_read('postgres-micromasters/creds/app', cache_prefix='heroku-micormasters') %}
    ADWORDS_CONVERSION_ID: 935224753
    CLIENT_ELASTICSEARCH_URL: '/api/v0/search/'
    DATABASE_URL: postgres://{{ pg_creds.data.username }}:{{ pg_creds.data.password }}@{{ rds_endpoint }}/mitxpro
    FEATURE_FINAL_GRADE_ALGORITHM: 'v1'
    FEATURE_PEARSON_EXAMS_SYNC: True
    HIREFIRE_TOKEN: __vault__::secret-{{ business_unit }}/production-apps/hirefire_token>data>value
    {% endif %}
    EDXORG_BASE_URL: {{ env_data.EDXORG_BASE_URL }}
    EDXORG_CLIENT_ID: __vault__::secret-{{ business_unit }}/{{ env_data.vault_env_path }}/>edx>data>client_id
    EDXORG_CLIENT_SECRET: __vault__::secret-{{ business_unit }}/{{ env_data.vault_env_path }}/>edx>data>client_secret
    ELASTICSEARCH_DEFAULT_PAGE_SIZE: 50
    ELASTICSEARCH_HTTP_AUTH: __vault__::secret-{{ business_unit }}/{{ env_data.env_name }}/es_http_auth>data>value
    ELASTICSEARCH_INDEX: {{ env_data.ELASTICSEARCH_INDEX }}
    ELASTICSEARCH_URL:   'https://elasticsearch'-{{ env_data.vault_env_path }}'.odl.mit.edu/'
    ENABLE_STUNNEL_AMAZON_RDS_FIX: True
    EXAMS_AUDIT_AWS_ACCESS_KEY_ID: __vault__:cache:aws-mitx/creds/read-write-{{ business_unit }}-app-{{ env_data.env_name }}>data>access_key
    EXAMS_AUDIT_AWS_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/read-write-odl-micromasters-audit-{{ env_data.env_name }}>data>secret_key
    EXAMS_AUDIT_ENABLED: True
    EXAMS_AUDIT_ENCRYPTION_FINGERPRINT: {{ exams_audit.encryption_fingerprint }}
    EXAMS_AUDIT_ENCRYPTION_PUBLIC_KEY: {{ exams_audit.encryption_public_key }}
    EXAMS_AUDIT_NACL_PUBLIC_KEY: {{ exams_audit.nacl_public_key }}
    EXAMS_AUDIT_S3_BUCKET: odl-micromasters-audit-{{ env_data.env_name }}
    EXAMS_SFTP_HOST: {{ exams_sftp.host }}
    EXAMS_SFTP_PASSWORD: {{ exams_sftp.password }}
    EXAMS_SFTP_UPLOAD_DIR: '.'
    EXAMS_SFTP_USERNAME: {{ exams_sftp.username }}
    EXAMS_SSO_CLIENT_CODE: 'MITX'
    EXAMS_SSO_PASSPHRASE: __vault__::secret-{{ business_unit }}/{{ env_data.vault_env_path }}/exams_sso>data>passphrase
    EXAMS_SSO_URL:  __vault__::secret-{{ business_unit }}/{{ env_data.vault_env_path }}/exams_sso>data>url
    FEATURE_ENABLE_PROGRAM_LETTER: True
    FEATURE_EXAMS_CARD_ENABLED: {{ env_data.FEATURE_EXAMS_CARD_ENABLED }}
    FEATURE_OPEN_DISCUSSIONS_CREATE_CHANNEL_UI: True
    FEATURE_OPEN_DISCUSSIONS_POST_UI: True
    FEATURE_OPEN_DISCUSSIONS_USER_SYNC: True
    FEATURE_OPEN_DISCUSSIONS_USER_UPDATE: False
    {% if env_data.env_name == 'rc' %}
    FEATURE_PROGRAM_LEARNERS_ENABLED: True
    FEATURE_SUPPRESS_PAYMENT_FOR_EXAM: False
    {% endif %}
    FEATURE_PROGRAM_RECORD_LINK: True
    FEATURE_USE_COMBINED_FINAL_GRADE: True
    GA_TRACKING_ID: {{ env_data.GA_TRACKING_ID }}
    GOOGLE_API_KEY: __vault__::secret-{{ business_unit }}/{{ env_data.vault_env_path }}/google_api_key>data>value
    GTM_CONTAINER_ID: {{ env_data.GTM_CONTAINER_ID }}
    MAILGUN_FROM_EMAIL: {{ env_data.MAILGUN_FROM_EMAIL }}
    MAILGUN_KEY: __vault__::secret-operations/global/mailgun-api-key>data>value
    MAILGUN_URL: {{ env_data.MAILGUN_URL }}
    MICROMASTERS_ADMIN_EMAIL: 'cuddle-bunnies@mit.edu'
    MICROMASTERS_CORS_ORIGIN_WHITELIST: {{ env_data.MICROMASTERS_CORS_ORIGIN_WHITELIST }}
    MICROMASTERS_DB_CONN_MAX_AGE: 0
    MICROMASTERS_DB_DISABLE_SSL: True
    MICROMASTERS_ECOMMERCE_EMAIL: __vault__::secret-{{ business_unit }}/{{ env_data.vault_env_path }}/ecommerce_email>data>value
    MICROMASTERS_EMAIL_HOST: __vault__::secret-operations/global/mit-smtp>data>relay_host
    MICROMASTERS_EMAIL_PASSWORD: __vault__::secret-operations/global/mit-smtp>data>relay_password
    MICROMASTERS_EMAIL_PORT: 587
    MICROMASTERS_EMAIL_TLS: True
    MICROMASTERS_EMAIL_USER: __vault__::secret-operations/global/mit-smtp>data>relay_username
    MICROMASTERS_ENVIRONMENT: {{ env_data.env_name }}
    MICROMASTERS_FROM_EMAIL: 'MITx MicroMasters <micromasters-support@mit.edu>'
    MICROMASTERS_LOG_LEVEL: {{ env_data.MICROMASTERS_LOG_LEVEL }}
    MICROMASTERS_SUPPORT_EMAIL: 'micromasters-support@mit.edu'
    MICROMASTERS_USE_S3: True
    MIDDLEWARE_FEATURE_FLAG_QS_PREFIX: {{ env_data.MIDDLEWARE_FEATURE_FLAG_QS_PREFIX }}
    NODE_MODULES_CACHE: False
    OPEN_DISCUSSIONS_API_USERNAME: {{ env_data.OPEN_DISCUSSIONS_API_USERNAME }}
    OPEN_DISCUSSIONS_BASE_URL: {{ env_data.OPEN_DISCUSSIONS_BASE_URL }}
    OPEN_DISCUSSIONS_COOKIE_DOMAIN: {{ env_data.OPEN_DISCUSSIONS_COOKIE_DOMAIN }}
    OPEN_DISCUSSIONS_COOKIE_NAME: {{ env_data.OPEN_DISCUSSIONS_COOKIE_NAME }}
    OPEN_DISCUSSIONS_JWT_SECRET: __vault__::secret-{{ business_unit }}/{{ env_data.env_name }}/jwt_secret>data>value
    OPEN_DISCUSSIONS_REDIRECT_COMPLETE_URL: '/complete/micromasters'
    OPEN_DISCUSSIONS_REDIRECT_URL: {{ env_data.OPEN_DISCUSSIONS_BASE_URL }}
    OPEN_DISCUSSIONS_SITE_KEY: 'micromasters'
    OPEN_EXCHANGE_RATES_APP_ID: __vault__::secret-{{ business_unit }}/global/open_exchange_rates_app_id>data>value
    OPEN_EXCHANGE_RATES_URL: 'https://openexchangerates.org/api/'
    PGBOUNCER_DEFAULT_POOL_SIZE: {{ env_data.PGBOUNCER_DEFAULT_POOL_SIZE }}
    PGBOUNCER_MAX_CLIENT_CONN: {{ env_data.PGBOUNCER_MAX_CLIENT_CONN }}
    SECRET_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/django-secret-key>data>value                            
    SENTRY_DSN: __vault__::secret-operations/global/micromasters/sentry-dsn>data>value
    STATUS_TOKEN:  __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/django-status-token>data>value                      
    UWSGI_PROCESS_COUNT: 2
    UWSGI_SOCKET_TIMEOUT: 1                      
    UWSGI_THREAD_COUNT: 50                   

schedule:
  refresh_{{ env_data.app_name }}_configs:
    days: 5
    function: state.sls
    args:
      - heroku.update_heroku_config
