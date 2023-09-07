{% set minion_id = salt.grains.get('id', '') %}
{% set environment = minion_id.split('-')[-1] %}

{% set env_dict = {
    'rc': {
      'app_name': 'mitxonline-rc',
      'env_name': 'rc',
      'env_stage': 'qa',
      'GOOGLE_TRACKING_ID': 'UA-5145472-46',
      'GOOGLE_TAG_MANAGER_ID': 'GTM-TW97MNR',
      'HUBSPOT_ID_PREFIX': 'mitxonline-rc',
      'HUBSPOT_PORTAL_ID': 23586992,
      'release_branch': 'release-candidate',
      'app_log_level': 'INFO',
      'sentry_log_level': 'ERROR',
      'logout_redirect_url': 'https://courses-qa.mitxonline.mit.edu/logout',
      'OPENEDX_API_BASE_URL': 'https://courses-qa.mitxonline.mit.edu',
      'openedx_environment': 'mitxonline-qa',
      'MAILGUN_FROM_EMAIL': 'MITx Online <no-reply@mitxonline-rc-mail.mitxonline.mit.edu>',
      'MAILGUN_SENDER_DOMAIN': 'mitxonline-rc-mail.mitxonline.mit.edu',
      'MITOL_GOOGLE_SHEETS_REFUNDS_REQUEST_WORKSHEET_ID': 0,
      'MITOL_GOOGLE_SHEETS_REFUNDS_FIRST_ROW': 4,
      'MITOL_PAYMENT_GATEWAY_CYBERSOURCE_SECURE_ACCEPTANCE_URL': 'https://testsecureacceptance.cybersource.com/pay',
      'MITOL_PAYMENT_GATEWAY_CYBERSOURCE_REST_API_ENVIRONMENT': 'apitest.cybersource.com',
      'MITXONLINE_BASE_URL': 'https://rc.mitxonline.mit.edu',
      'MITXONLINE_SECURE_SSL_HOST': 'mitxonline-rc.mitxonline.mit.edu',
      'CRON_COURSE_CERTIFICATES_HOURS': 18,
      },
    'production': {
      'app_name': 'mitxonline-production',
      'env_name': 'production',
      'env_stage': 'production',
      'GOOGLE_TRACKING_ID': 'UA-5145472-48',
      'GOOGLE_TAG_MANAGER_ID': 'GTM-M47BLXN',
      'HUBSPOT_ID_PREFIX': 'mitxonline',
      'HUBSPOT_PORTAL_ID': 20596155,
      'release_branch': 'release',
      'app_log_level': 'INFO',
      'sentry_log_level': 'ERROR',
      'logout_redirect_url': 'https://courses.mitxonline.mit.edu/logout',
      'OPENEDX_API_BASE_URL': 'https://courses.mitxonline.mit.edu',
      'openedx_environment': 'mitxonline-production',
      'MAILGUN_FROM_EMAIL': 'MITx Online <no-reply@mail.mitxonline.mit.edu>',
      'MAILGUN_SENDER_DOMAIN': 'mail.mitxonline.mit.edu',
      'MITOL_GOOGLE_SHEETS_REFUNDS_REQUEST_WORKSHEET_ID': 0,
      'MITOL_GOOGLE_SHEETS_REFUNDS_FIRST_ROW': 4,
      'MITOL_PAYMENT_GATEWAY_CYBERSOURCE_SECURE_ACCEPTANCE_URL': 'https://secureacceptance.cybersource.com/pay',
      'MITOL_PAYMENT_GATEWAY_CYBERSOURCE_REST_API_ENVIRONMENT': 'api.cybersource.com',
      'MITXONLINE_BASE_URL': 'https://mitxonline.mit.edu',
      'MITXONLINE_SECURE_SSL_HOST': 'mitxonline.mit.edu',
      'CRON_COURSE_CERTIFICATES_HOURS': 18,
      }
} %}
{% set env_data = env_dict[environment] %}
{% set business_unit = 'mitxonline' %}

proxy:
  proxytype: heroku

heroku:
  app_name: {{ env_data.app_name }}
  api_key: __vault__::secret-operations/global/heroku/odl-devops-api-key>data>value
  config_vars:
    AWS_ACCESS_KEY_ID:  __vault__:cache:aws-mitx/creds/mitxonline>data>access_key
    AWS_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/mitxonline>data>secret_key
    AWS_STORAGE_BUCKET_NAME: 'ol-mitxonline-app-{{ env_data.env_stage}}'
    CRON_COURSERUN_SYNC_HOURS: '*'
    CRON_COURSE_CERTIFICATES_HOURS: {{ env_data.CRON_COURSE_CERTIFICATES_HOURS }}
    {% if env_data.env_name == 'production' %}
    HIREFIRE_TOKEN: __vault__::secret-{{ business_unit }}/production-apps/hirefire_token>data>value
    {% endif %}
    MITX_ONLINE_SUPPORT_EMAIL: 'mitxonline-support@mit.edu'
    {% set rds_endpoint = salt.boto_rds.get_endpoint('mitxonline-{}-app-db'.format(env_data.env_stage)) %}
    {% set pg_creds = salt.vault.cached_read('postgres-mitxonline/creds/app', cache_prefix='heroku-mitxonline') %}
    DATABASE_URL: postgres://{{ pg_creds.data.username }}:{{ pg_creds.data.password }}@{{ rds_endpoint }}/mitxonline
    FEATURE_SYNC_ON_DASHBOARD_LOAD: True
    FEATURE_IGNORE_EDX_FAILURES: True
    GA_TRACKING_ID: {{ env_data.GOOGLE_TRACKING_ID }}
    GTM_TRACKING_ID: {{ env_data.GOOGLE_TAG_MANAGER_ID }}
    HUBSPOT_PIPELINE_ID: '19817792'
    HUBSPOT_PORTAL_ID: {{ env_data.HUBSPOT_PORTAL_ID }}
    LOGOUT_REDIRECT_URL: {{ env_data.logout_redirect_url }}
    MAILGUN_KEY: __vault__::secret-operations/global/mailgun-api-key>data>value
    MAILGUN_FROM_EMAIL: {{ env_data.MAILGUN_FROM_EMAIL }}
    MAILGUN_SENDER_DOMAIN: {{ env_data.MAILGUN_SENDER_DOMAIN }}
    MITOL_GOOGLE_SHEETS_PROCESSOR_APP_NAME: MITx Online ({{ env_data.env_name }})
    MITOL_GOOGLE_SHEETS_DRIVE_CLIENT_ID: __vault__::secret-mitxonline/google-sheets-refunds>data>drive-client-id
    MITOL_GOOGLE_SHEETS_DRIVE_CLIENT_SECRET: __vault__::secret-mitxonline/google-sheets-refunds>data>drive-client-secret
    MITOL_GOOGLE_SHEETS_DRIVE_API_PROJECT_ID: __vault__::secret-mitxonline/google-sheets-refunds>data>drive-api-project-id
    MITOL_GOOGLE_SHEETS_ENROLLMENT_CHANGE_SHEET_ID: __vault__::secret-mitxonline/google-sheets-refunds>data>enrollment-change-sheet-id
    MITOL_GOOGLE_SHEETS_REFUNDS_COMPLETED_DATE_COL: 12
    MITOL_GOOGLE_SHEETS_REFUNDS_ERROR_COL: 13
    MITOL_GOOGLE_SHEETS_REFUNDS_SKIP_ROW_COL: 14
    MITOL_GOOGLE_SHEETS_REFUNDS_REQUEST_WORKSHEET_ID: {{ env_data.MITOL_GOOGLE_SHEETS_REFUNDS_REQUEST_WORKSHEET_ID }}
    MITOL_GOOGLE_SHEETS_REFUNDS_FIRST_ROW: {{ env_data.MITOL_GOOGLE_SHEETS_REFUNDS_FIRST_ROW }}
    MITOL_HUBSPOT_API_PRIVATE_TOKEN: __vault__::secret-{{ business_unit }}/hubspot-api-private-token>data>value
    MITOL_HUBSPOT_API_ID_PREFIX: {{ env_data.HUBSPOT_ID_PREFIX }}
    MITOL_PAYMENT_GATEWAY_CYBERSOURCE_ACCESS_KEY: __vault__::secret-{{ business_unit }}/{{ env_data.env_name }}/cybersource-credentials>data>access-key
    MITOL_PAYMENT_GATEWAY_CYBERSOURCE_PROFILE_ID: __vault__::secret-{{ business_unit }}/{{ env_data.env_name }}/cybersource-credentials>data>profile-id
    MITOL_PAYMENT_GATEWAY_CYBERSOURCE_SECURE_ACCEPTANCE_URL: {{ env_data.MITOL_PAYMENT_GATEWAY_CYBERSOURCE_SECURE_ACCEPTANCE_URL }}
    MITOL_PAYMENT_GATEWAY_CYBERSOURCE_REST_API_ENVIRONMENT: {{ env_data.MITOL_PAYMENT_GATEWAY_CYBERSOURCE_REST_API_ENVIRONMENT }}
    MITOL_PAYMENT_GATEWAY_CYBERSOURCE_SECURITY_KEY:  __vault__::secret-{{ business_unit }}/{{ env_data.env_name }}/cybersource-credentials>data>security-key
    MITOL_PAYMENT_GATEWAY_CYBERSOURCE_MERCHANT_ID: __vault__::secret-{{ business_unit }}/{{ env_data.env_name }}/cybersource-credentials>data>merchant-id
    MITOL_PAYMENT_GATEWAY_CYBERSOURCE_MERCHANT_SECRET: __vault__::secret-{{ business_unit }}/{{ env_data.env_name }}/cybersource-credentials>data>merchant-secret
    MITOL_PAYMENT_GATEWAY_CYBERSOURCE_MERCHANT_SECRET_KEY_ID: __vault__::secret-{{ business_unit }}/{{ env_data.env_name }}/cybersource-credentials>data>merchant-secret-key-id
    MITX_ONLINE_ADMIN_EMAIL: 'cuddle-bunnies@mit.edu'
    MITX_ONLINE_BASE_URL: {{ env_data.MITXONLINE_BASE_URL }}
    MITX_ONLINE_DB_CONN_MAX_AGE: 0
    MITX_ONLINE_DB_DISABLE_SSL: True    # pgbouncer buildpack uses stunnel to handle encryption
    MITX_ONLINE_ENVIRONMENT: {{ env_data.env_name }}
    MITX_ONLINE_FROM_EMAIL: 'MITx Online <support@mitxonline.mit.edu>'
    MITX_ONLINE_LOG_LEVEL: {{ env_data.app_log_level }}
    MITX_ONLINE_OAUTH_PROVIDER: 'mitxonline-oauth2'
    MITX_ONLINE_REFINE_OIDC_CONFIG_CLIENT_ID: __vault__::secret-mitxonline/refine-oidc>data>client-id
    MITX_ONLINE_REGISTRATION_ACCESS_TOKEN:  __vault__:gen_if_missing:secret-{{ business_unit }}/{{ env_data.openedx_environment }}/mitxonline-registration-access-token>data>value
    MITX_ONLINE_REPLY_TO_ADDRESS: 'MITx Online <support@mitxonline.mit.edu>'
    MITX_ONLINE_SECURE_SSL_REDIRECT: True
    MITX_ONLINE_SECURE_SSL_HOST: {{ env_data.MITXONLINE_SECURE_SSL_HOST }}
    MITX_ONLINE_USE_S3: True
    NODE_MODULES_CACHE: False
    OIDC_RSA_PRIVATE_KEY: __vault__::secret-mitxonline/refine-oidc>data>rsa-private-key
    OPEN_EXCHANGE_RATES_APP_ID: __vault__::secret-mitxonline/open-exchange-rates>data>app_id
    OPEN_EXCHANGE_RATES_URL: https://openexchangerates.org/api/
    OPENEDX_API_BASE_URL: {{ env_data.OPENEDX_API_BASE_URL}}
    OPENEDX_API_CLIENT_ID: __vault__::secret-{{ business_unit }}/{{ environment }}/openedx-api-client>data>client-id
    OPENEDX_API_CLIENT_SECRET: __vault__::secret-{{ business_unit }}/{{ environment }}/openedx-api-client>data>client-secret
    OPENEDX_API_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ env_data.openedx_environment }}/edx-api-key>data>value
    OPENEDX_SERVICE_WORKER_API_TOKEN: __vault__::secret-{{ business_unit }}/{{ environment }}/openedx-service-worker-api-token>data>value
    OPENEDX_SERVICE_WORKER_USERNAME: login_service_user
    PGBOUNCER_DEFAULT_POOL_SIZE: 50
    PGBOUNCER_MIN_POOL_SIZE: 5
    RECAPTCHA_SITE_KEY: __vault__::secret-mitxonline/recaptcha-keys>data>site_key
    RECAPTCHA_SECRET_KEY: __vault__::secret-mitxonline/recaptcha-keys>data>secret_key
    OPENEDX_RETIREMENT_SERVICE_WORKER_CLIENT_ID: __vault__::secret-mitxonline/openedx-retirement-service-worker>data>client_id
    OPENEDX_RETIREMENT_SERVICE_WORKER_CLIENT_SECRET: __vault__::secret-mitxonline/openedx-retirement-service-worker>data>client_secret
    SECRET_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/django-secret-key>data>value
    SENTRY_DSN: __vault__::secret-operations/global/mitxonline/sentry-dsn>data>value
    SENTRY_LOG_LEVEL: {{ env_data.sentry_log_level }}
    SITE_NAME: "MITx Online"
    STATUS_TOKEN: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/django-status-token>data>value
    USE_X_FORWARDED_HOST: True
    ZENDESK_HELP_WIDGET_ENABLED: True
    POSTHOG_API_TOKEN: __vault__::secret-{{ business_unit }}/posthog-credentials>data>api-token
    POSTHOG_API_HOST: "https://app.posthog.com"
    HUBSPOT_HOME_PAGE_FORM_GUID: __vault__::secret-{{ business_unit }}/hubspot>data>formId
    HUBSPOT_PORTAL_ID:__vault__::secret-{{ business_unit }}/hubspot>data>portalId

schedule:
  refresh_{{ env_data.app_name }}_configs:
    days: 5
    function: state.sls
    args:
      - heroku.update_heroku_config
