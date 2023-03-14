{% set minion_id = salt.grains.get('id', '') %}
{% set environment = minion_id.split('-')[-1] %}

{% set env_dict = {
    'ci': {
      'app_name': 'micromasters-ci',
      'ALLOWED_HOSTS': '["micromasters-ci.odl.mit.edu"]',
      'CYBERSOURCE_SECURE_ACCEPTANCE_URL': 'https://testsecureacceptance.cybersource.com/pay',
      'EDXORG_BASE_URL': 'https://lms-ci.mitx.mit.edu',
      'ELASTICSEARCH_INDEX': 'micromasters-ci',
      'env_name': 'ci',
      'FEATURE_EXAMS_CARD_ENABLED': False,
      'GA_TRACKING_ID': 'UA-5145472-14',
      'GTM_CONTAINER_ID': 'GTM-NB27R8L',
      'MAILGUN_FROM_EMAIL': 'no-reply@micromasters-rc-mail.odl.mit.edu',
      'MAILGUN_URL': 'https://api.mailgun.net/v3/micromasters-rc-mail.odl.mit.edu',
      'MICROMASTERS_BASE_URL': 'https://micromasters-ci.odl.mit.edu',
      'MICROMASTERS_CORS_ORIGIN_WHITELIST': '["discussions-ci.odl.mit.edu"]',
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
      'aws_env': 'qa',
      'ALLOWED_HOSTS': '["micromasters-rc.odl.mit.edu"]',
      'CLOUDFRONT_DIST': 'd3o95baofem9lo',
      'CYBERSOURCE_SECURE_ACCEPTANCE_URL': 'https://testsecureacceptance.cybersource.com/pay',
      'EDXORG_BASE_URL': 'https://courses.stage.edx.org',
      'ELASTICSEARCH_INDEX': 'micromasters-rc',
      'ELASTICSEARCH_SHARD_COUNT': 3,
      'env_name': 'rc',
      'FEATURE_EXAMS_CARD_ENABLED': False,
      'GA_TRACKING_ID': 'UA-5145472-14',
      'GTM_CONTAINER_ID': 'GTM-NB27R8L',
      'MAILGUN_FROM_EMAIL': 'no-reply@micromasters-rc-mail.odl.mit.edu',
      'MAILGUN_URL': 'https://api.mailgun.net/v3/micromasters-rc-mail.odl.mit.edu',
      'MICROMASTERS_BASE_URL': 'https://micromasters-rc.odl.mit.edu',
      'MICROMASTERS_CORS_ORIGIN_WHITELIST': '["discussions-rc.odl.mit.edu"]',
      'MICROMASTERS_LOG_LEVEL': 'DEBUG',
      'MIDDLEWARE_FEATURE_FLAG_QS_PREFIX': 'BGA',
      'MITXONLINE_BASE_URL': 'https://courses-qa.mitxonline.mit.edu/',
      'MITXONLINE_CALLBACK_URL': 'https://courses-qa.mitxonline.mit.edu/',
      'MITXONLINE_URL': 'https://rc.mitxonline.mit.edu/',
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
      'aws_env': 'production',
      'ALLOWED_HOSTS': '["micromasters.mit.edu", "mmfin.mit.edu", "mm.mit.edu"]',
      'CLOUDFRONT_DIST': 'do5zh7b0lqdye',
      'CYBERSOURCE_SECURE_ACCEPTANCE_URL': 'https://secureacceptance.cybersource.com/pay',
      'EDXORG_BASE_URL': 'https://courses.edx.org',
      'ELASTICSEARCH_INDEX': 'micromasters',
      'ELASTICSEARCH_SHARD_COUNT': 2,
      'env_name': 'production',
      'FEATURE_EXAMS_CARD_ENABLED': True,
      'GA_TRACKING_ID': 'UA-5145472-10',
      'GTM_CONTAINER_ID': 'GTM-NB27R8L',
      'MAILGUN_FROM_EMAIL': 'no-reply@micromasters.odl.mit.edu',
      'MAILGUN_URL': 'https://api.mailgun.net/v3/micromasters.odl.mit.edu',
      'MICROMASTERS_BASE_URL': 'https://micromasters.mit.edu',
      'MICROMASTERS_CORS_ORIGIN_WHITELIST': '["open.mit.edu"]',
      'MICROMASTERS_LOG_LEVEL': 'INFO',
      'MIDDLEWARE_FEATURE_FLAG_QS_PREFIX': 'XIQ',
      'MITXONLINE_BASE_URL': 'https://courses.mitxonline.mit.edu',
      'MITXONLINE_CALLBACK_URL': 'https://courses.mitxonline.mit.edu',
      'MITXONLINE_URL': 'https://mitxonline.mit.edu/',
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
{% set cybersource_creds = salt.vault.read('secret-' ~ business_unit ~ '/cybersource').data %}
# Those can be removed once this issue is closed https://github.com/mitodl/micromasters/issues/5314
{% set exams_audit = salt.vault.read('secret-' ~ business_unit ~ '/exams/audit').data %}
{% set exams_sftp = salt.vault.read('secret-' ~ business_unit ~ '/exams/sftp').data %}
{% set exams_sso = salt.vault.read('secret-' ~ business_unit ~ '/exams/sso').data %}

proxy:
  proxytype: heroku

heroku:
  app_name: {{ env_data.app_name }}
  api_key: __vault__::secret-operations/heroku>data>api_key
  config_vars:
    ALLOWED_HOSTS: '{{ env_data.ALLOWED_HOSTS|tojson }}'
    AWS_ACCESS_KEY_ID: __vault__:cache:aws-mitx/creds/{{ business_unit }}-app>data>access_key
    AWS_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/{{ business_unit }}-app>data>secret_key
    AWS_STORAGE_BUCKET_NAME: ol-{{ business_unit}}-app-{{ env_data.env_name }}
    BATCH_UPDATE_RATE_LIMIT: '2/m'
    CYBERSOURCE_ACCESS_KEY: {{ cybersource_creds.access_key }}
    CYBERSOURCE_PROFILE_ID: {{ cybersource_creds.profile_id }}
    CYBERSOURCE_REFERENCE_PREFIX: {{ env_data.env_name }}
    CYBERSOURCE_SECURE_ACCEPTANCE_URL: {{ env_data.CYBERSOURCE_SECURE_ACCEPTANCE_URL }}
    CYBERSOURCE_SECURITY_KEY: {{ cybersource_creds.security_key }}
    EDXORG_BASE_URL: {{ env_data.EDXORG_BASE_URL }}
    EDXORG_CALLBACK_URL: {{ env_data.EDXORG_BASE_URL }}
    EDXORG_CLIENT_ID: __vault__::secret-{{ business_unit }}/>edx>data>client_id
    EDXORG_CLIENT_SECRET: __vault__::secret-{{ business_unit }}/>edx>data>client_secret
    ENABLE_STUNNEL_AMAZON_RDS_FIX: True
    EXAMS_AUDIT_NACL_PUBLIC_KEY: {{ exams_audit.nacl_public_key }}
    EXAMS_SFTP_HOST: {{ exams_sftp.host }}
    EXAMS_SFTP_PASSWORD: {{ exams_sftp.password }}
    EXAMS_SFTP_UPLOAD_DIR: '.'
    EXAMS_SFTP_USERNAME: {{ exams_sftp.username }}
    FEATURE_EXAMS_CARD_ENABLED: {{ env_data.FEATURE_EXAMS_CARD_ENABLED }}
    FEATURE_FINAL_GRADE_ALGORITHM: 'v1'
    FEATURE_OPEN_DISCUSSIONS_CREATE_CHANNEL_UI: True
    FEATURE_OPEN_DISCUSSIONS_POST_UI: True
    FEATURE_OPEN_DISCUSSIONS_USER_SYNC: True
    FEATURE_OPEN_DISCUSSIONS_USER_UPDATE: False
    FEATURE_PROGRAM_RECORD_LINK: True
    GA_TRACKING_ID: {{ env_data.GA_TRACKING_ID }}
    GOOGLE_API_KEY: __vault__::secret-{{ business_unit }}/google>data>api_key
    GTM_CONTAINER_ID: {{ env_data.GTM_CONTAINER_ID }}
    MAILGUN_FROM_EMAIL: {{ env_data.MAILGUN_FROM_EMAIL }}
    MAILGUN_KEY: __vault__::secret-operations/mailgun>data>api_key
    MAILGUN_URL: {{ env_data.MAILGUN_URL }}
    MICROMASTERS_BASE_URL: {{ env_data.MICROMASTERS_BASE_URL }}
    MICROMASTERS_CORS_ORIGIN_WHITELIST: '{{ env_data.MICROMASTERS_CORS_ORIGIN_WHITELIST|tojson }}'
    MICROMASTERS_DB_CONN_MAX_AGE: 0
    MICROMASTERS_DB_DISABLE_SSL: True
    MICROMASTERS_EMAIL_HOST: __vault__::secret-operations/mit-smtp>data>relay_host
    MICROMASTERS_EMAIL_PASSWORD: __vault__::secret-operations/mit-smtp>data>relay_password
    MICROMASTERS_EMAIL_PORT: 587
    MICROMASTERS_EMAIL_TLS: True
    MICROMASTERS_EMAIL_USER: __vault__::secret-operations/mit-smtp>data>relay_username
    MICROMASTERS_ENVIRONMENT: {{ env_data.env_name }}
    MICROMASTERS_FROM_EMAIL: 'MITx MicroMasters <micromasters-support@mit.edu>'
    MICROMASTERS_LOG_LEVEL: {{ env_data.MICROMASTERS_LOG_LEVEL }}
    MICROMASTERS_SUPPORT_EMAIL: 'micromasters-support@mit.edu'
    MICROMASTERS_USE_S3: True
    NODE_MODULES_CACHE: False
    OPEN_DISCUSSIONS_API_USERNAME: {{ env_data.OPEN_DISCUSSIONS_API_USERNAME }}
    OPEN_DISCUSSIONS_BASE_URL: {{ env_data.OPEN_DISCUSSIONS_BASE_URL }}
    OPEN_DISCUSSIONS_COOKIE_DOMAIN: {{ env_data.OPEN_DISCUSSIONS_COOKIE_DOMAIN }}
    OPEN_DISCUSSIONS_COOKIE_NAME: {{ env_data.OPEN_DISCUSSIONS_COOKIE_NAME }}
    OPEN_DISCUSSIONS_JWT_SECRET: __vault__::secret-{{ business_unit }}/open-discussions>data>jwt_secret
    OPEN_DISCUSSIONS_REDIRECT_COMPLETE_URL: '/complete/micromasters'
    OPEN_DISCUSSIONS_REDIRECT_URL: {{ env_data.OPEN_DISCUSSIONS_BASE_URL }}
    OPEN_DISCUSSIONS_SITE_KEY: 'micromasters'
    OPEN_EXCHANGE_RATES_APP_ID: __vault__::secret-{{ business_unit }}/open-exchange-rates>data>app_id
    OPEN_EXCHANGE_RATES_URL: 'https://openexchangerates.org/api/'
    OPENSEARCH_HTTP_AUTH: __vault__::secret-{{ business_unit }}/opensearch>data>http_auth
    OPENSEARCH_INDEX: 'micromasters'
    OPENSEARCH_URL: __vault__::secret-{{ business_unit }}/opensearch>data>url
    PGBOUNCER_DEFAULT_POOL_SIZE: {{ env_data.PGBOUNCER_DEFAULT_POOL_SIZE }}
    PGBOUNCER_MAX_CLIENT_CONN: {{ env_data.PGBOUNCER_MAX_CLIENT_CONN }}
    SECRET_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/django>data>secret_key
    SENTRY_AUTH_TOKEN: __vault__::secret-{{ business_unit }}/sentry>data>auth_token
    SENTRY_DSN: __vault__::secret-{{ business_unit }}/sentry>data>dsn
    SENTRY_ORG_NAME: 'mit-office-of-digital-learning'
    SENTRY_PROJECT_NAME: 'micromasters'
    STATUS_TOKEN: __vault__:gen_if_missing:secret-{{ business_unit }}/django>data>status_token
    UWSGI_PROCESS_COUNT: 4
    UWSGI_SOCKET_TIMEOUT: 1
    UWSGI_THREAD_COUNT: 50
    {% if env_data.env_name == 'production' %}
    ADWORDS_CONVERSION_ID: 935224753
    FEATURE_PEARSON_EXAMS_SYNC: True
    {% endif %}
    {% if env_data.env_name != 'ci' %}
    {% set rds_endpoint = salt.boto_rds.get_endpoint('micromasters-{env}-app-db'.format(env=env_data.aws_env)) %}
    {% set pg_creds = salt.vault.cached_read('postgres-micromasters/creds/app', cache_prefix='heroku-micromasters') %}
    CLIENT_ELASTICSEARCH_URL: '/api/v0/search/'
    CLOUDFRONT_DIST: {{ env_data.CLOUDFRONT_DIST }}
    DATABASE_URL: postgres://{{ pg_creds.data.username }}:{{ pg_creds.data.password }}@{{ rds_endpoint }}/micromasters
    ENABLE_STUNNEL_AMAZON_RDS_FIX: True
    EXAMS_AUDIT_AWS_ACCESS_KEY_ID: {{ exams_audit.access_key }}
    EXAMS_AUDIT_AWS_SECRET_ACCESS_KEY: {{ exams_audit.secret_key }}
    EXAMS_AUDIT_ENABLED: True
    EXAMS_AUDIT_ENCRYPTION_FINGERPRINT: {{ exams_audit.encryption_fingerprint }}
    EXAMS_AUDIT_ENCRYPTION_PUBLIC_KEY: {{ exams_audit.encryption_public_key }}
    EXAMS_AUDIT_S3_BUCKET: odl-micromasters-audit-{{ env_data.env_name }}
    EXAMS_SSO_CLIENT_CODE: 'MITX'
    EXAMS_SSO_PASSPHRASE: {{ exams_sso.passphrase }}
    EXAMS_SSO_URL: {{ exams_sso.url }}
    FEATURE_ENABLE_PROGRAM_LETTER: True
    FEATURE_MITXONLINE_LOGIN: True
    MICROMASTERS_ADMIN_EMAIL: 'cuddle-bunnies@mit.edu'
    MICROMASTERS_DB_CONN_MAX_AGE: 0
    MICROMASTERS_DB_DISABLE_SSL: True
    MICROMASTERS_ECOMMERCE_EMAIL: 'cuddle-bunnies@mit.edu'
    MIDDLEWARE_FEATURE_FLAG_QS_PREFIX: {{ env_data.MIDDLEWARE_FEATURE_FLAG_QS_PREFIX }}
    MITXONLINE_BASE_URL: {{ env_data.MITXONLINE_BASE_URL }}
    MITXONLINE_CALLBACK_URL: {{ env_data.MITXONLINE_CALLBACK_URL }}
    MITXONLINE_CLIENT_ID: __vault__::secret-{{ business_unit }}/mitxonline>data>oauth_client_id
    MITXONLINE_CLIENT_SECRET: __vault__::secret-{{ business_unit }}/mitxonline>data>oauth_client_secret
    MITXONLINE_STAFF_ACCESS_TOKEN: __vault__::secret-{{ business_unit }}/mitxonline>data>staff_access_token
    MITXONLINE_URL: {{ env_data.MITXONLINE_URL }}
    {% endif %}

schedule:
  refresh_{{ env_data.app_name }}_configs:
    days: 5
    function: state.sls
    args:
      - heroku.update_heroku_config
