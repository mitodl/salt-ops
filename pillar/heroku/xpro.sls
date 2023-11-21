{% set minion_id = salt.grains.get('id', '') %}
{% set environment = minion_id.split('-')[-1] %}

{% set env_dict = {
    'ci': {
      'app_name': 'xpro-ci',
      'aws_env': 'ci',
      'env_name': 'ci',
      'GOOGLE_TRACKING_ID': 'UA-5145472-40',
      'GOOGLE_TAG_MANAGER_ID': 'GTM-KJHRV6K',
      'release_branch': 'master',
      'app_log_level': 'INFO',
      'sentry_log_level': 'ERROR',
      'logout_redirect_url': 'https://courses-ci.xpro.mit.edu/logout',
      'OPENEDX_API_BASE_URL': 'https://courses-ci.xpro.mit.edu',
      'openedx_environment': 'mitxpro-qa',
      'CYBERSOURCE_SECURE_ACCEPTANCE_URL': 'https://testsecureacceptance.cybersource.com/pay',
      'CYBERSOURCE_WSDL_URL': 'https://ics2wstest.ic3.com/commerce/1.x/transactionProcessor/CyberSourceTransaction_1.154.wsdl',
      'DIGITAL_CREDENTIALS_SUPPORTED_RUNS': '',
      'HUBSPOT_FOOTER_FORM_GUID': '3ab7232f-13e3-43b6-aa6a-305f92208109',
      'HUBSPOT_ID_PREFIX': 'xpro-ci',
      'HUBSPOT_NEW_COURSES_FORM_GUID': '0c3a6036-a8b2-4de7-80a7-1e409322a6aa',
      'HUBSPOT_PORTAL_ID': 23128026,
      'MAILGUN_FROM_EMAIL': 'MIT xPRO <no-reply@xpro-ci-mail.odl.mit.edu>',
      'MAILGUN_SENDER_DOMAIN': 'xpro-ci-mail.odl.mit.edu',
      'MITXPRO_BASE_URL': 'https://xpro-ci.odl.mit.edu',
      'MITXPRO_SECURE_SSL_HOST': 'xpro-ci.odl.mit.edu',
      'ENABLE_ORDER_RECEIPTS': True,
      'SHEETS_MONITORING_FREQUENCY': 86400,
      'SHEETS_DEFERRAL_FIRST_ROW': 184,
      'SHEETS_REFUND_FIRST_ROW': 254,
      'SHEETS_REFUND_PROCESSOR_COL': 11,
      'SHEETS_REFUND_COMPLETED_DATE_COL': 12,
      'SHEETS_REFUND_ERROR_COL': 13,
      'SHEETS_REFUND_SKIP_ROW_COL': 14,
      'vault_env_path': 'rc-apps',
      'VOUCHER_COMPANY_ID': 1
      },
    'rc': {
      'app_name': 'xpro-rc',
      'aws_env': 'qa',
      'env_name': 'rc',
      'GOOGLE_TRACKING_ID': 'UA-5145472-40',
      'GOOGLE_TAG_MANAGER_ID': 'GTM-KJHRV6K',
      'release_branch': 'release-candidate',
      'app_log_level': 'INFO',
      'sentry_log_level': 'WARN',
      'logout_redirect_url': 'https://courses-rc.xpro.mit.edu/logout',
      'OPENEDX_API_BASE_URL': 'https://courses-rc.xpro.mit.edu',
      'openedx_environment': 'mitxpro-qa',
      'CSRF_TRUSTED_ORIGINS': 'rc.xpro.mit.edu,xpro-rc.odl.mit.edu',
      'CYBERSOURCE_SECURE_ACCEPTANCE_URL': 'https://testsecureacceptance.cybersource.com/pay',
      'CYBERSOURCE_WSDL_URL': 'https://ics2wstest.ic3.com/commerce/1.x/transactionProcessor/CyberSourceTransaction_1.154.wsdl',
      'DIGITAL_CREDENTIALS_SUPPORTED_RUNS': 'course-v1:xPRO+TestCourse1+R2,course-v1:xPRO+TestCourse2+R2,program-v1:xPRO+TestProgram',
      'HUBSPOT_FOOTER_FORM_GUID': '3ab7232f-13e3-43b6-aa6a-305f92208109',
      'HUBSPOT_ID_PREFIX': 'xpro-rc',
      'HUBSPOT_NEW_COURSES_FORM_GUID': '0c3a6036-a8b2-4de7-80a7-1e409322a6aa',
      'HUBSPOT_PORTAL_ID': 23128026,
      'MAILGUN_FROM_EMAIL': 'MIT xPRO <no-reply@xpro-rc-mail.odl.mit.edu>',
      'MAILGUN_SENDER_DOMAIN': 'xpro-rc-mail.odl.mit.edu',
      'MITXPRO_BASE_URL': 'https://rc.xpro.mit.edu',
      'MITXPRO_SECURE_SSL_HOST': 'rc.xpro.mit.edu',
      'vault_env_path': 'rc-apps',
      'ENABLE_ORDER_RECEIPTS': True,
      'SHEETS_MONITORING_FREQUENCY': 43200,
      'SHEETS_DEFERRAL_FIRST_ROW': 184,
      'SHEETS_REFUND_FIRST_ROW': 254,
      'SHEETS_REFUND_PROCESSOR_COL': 12,
      'SHEETS_REFUND_COMPLETED_DATE_COL': 13,
      'SHEETS_REFUND_ERROR_COL': 14,
      'SHEETS_REFUND_SKIP_ROW_COL': 15,
      'VOUCHER_COMPANY_ID': 1
      },
    'production': {
      'app_name': 'xpro-production',
      'aws_env': 'production',
      'env_name': 'production',
      'GOOGLE_TRACKING_ID': 'UA-5145472-38',
      'GOOGLE_TAG_MANAGER_ID': 'GTM-KG4FR7J',
      'release_branch': 'release',
      'app_log_level': 'INFO',
      'sentry_log_level': 'WARN',
      'logout_redirect_url': 'https://courses.xpro.mit.edu/logout',
      'OPENEDX_API_BASE_URL': 'https://courses.xpro.mit.edu',
      'openedx_environment': 'mitxpro-production',
      'CSRF_TRUSTED_ORIGINS': 'xpro.mit.edu,xpro-web.odl.mit.edu',
      'CYBERSOURCE_SECURE_ACCEPTANCE_URL': 'https://secureacceptance.cybersource.com/pay',
      'CYBERSOURCE_WSDL_URL': 'https://ics2wsa.ic3.com/commerce/1.x/transactionProcessor/CyberSourceTransaction_1.154.wsdl',
      'DIGITAL_CREDENTIALS_SUPPORTED_RUNS': '',
      'HUBSPOT_FOOTER_FORM_GUID': '6f7e46ec-f757-43a4-b109-597210df0f75',
      'HUBSPOT_ID_PREFIX': 'xpro',
      'HUBSPOT_NEW_COURSES_FORM_GUID': 'ad5d54e5-5ca9-4255-9c17-fa222e0a9b82',
      'HUBSPOT_PORTAL_ID': 4994459,
      'MAILGUN_FROM_EMAIL': 'MIT xPRO <no-reply@xpro.mit.edu>',
      'MAILGUN_SENDER_DOMAIN': 'xpro.mit.edu',
      'MITXPRO_BASE_URL': 'https://xpro.mit.edu',
      'MITXPRO_SECURE_SSL_HOST': 'xpro.mit.edu',
      'ENABLE_ORDER_RECEIPTS': True,
      'SHEETS_MONITORING_FREQUENCY': 3600,
      'SHEETS_DEFERRAL_FIRST_ROW': 234,
      'SHEETS_REFUND_FIRST_ROW': 287,
      'SHEETS_REFUND_PROCESSOR_COL': 12,
      'SHEETS_REFUND_COMPLETED_DATE_COL': 13,
      'SHEETS_REFUND_ERROR_COL': 14,
      'SHEETS_REFUND_SKIP_ROW_COL': 15,
      'vault_env_path': 'production-apps',
      'VOUCHER_COMPANY_ID': 4
      }
} %}
{% set env_data = env_dict[environment] %}
{% set business_unit = 'mitxpro' %}
{% set cybersource_creds = salt.vault.read('secret-' ~ business_unit ~ '/' ~ env_data.vault_env_path ~ '/cybersource') %}
{% set smtp_config = salt.vault.read('secret-' ~ business_unit ~ '/' ~ business_unit ~ '-' ~ env_data.env_name ~ '/smtp_config') %}
{% set rds_endpoint = salt.boto_rds.get_endpoint('xpro-db-applications-{env}'.format(env=env_data.aws_env)) %}

proxy:
  proxytype: heroku

heroku:
  app_name: {{ env_data.app_name }}
  api_key: __vault__::secret-operations/global/heroku/mitx-devops-api-key>data>value
  config_vars:
    AWS_ACCESS_KEY_ID:  __vault__:cache:aws-mitx/creds/xpro-app>data>access_key
    AWS_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/xpro-app>data>secret_key
    AWS_STORAGE_BUCKET_NAME: 'xpro-app-{{ env_data.env_name }}'
    COUPON_REQUEST_SHEET_ID: __vault__::secret-xpro/google-sheets>data>sheet_id
    CRON_COURSERUN_SYNC_HOURS: '*'
    CYBERSOURCE_ACCESS_KEY: {{ cybersource_creds.data.access_key }}
    CYBERSOURCE_MERCHANT_ID: 'mit_odl_xpro'
    CYBERSOURCE_PROFILE_ID: {{ cybersource_creds.data.profile_id }}
    CYBERSOURCE_REFERENCE_PREFIX: xpro-{{ env_data.env_name }}
    CYBERSOURCE_SECURE_ACCEPTANCE_URL: {{ env_data.CYBERSOURCE_SECURE_ACCEPTANCE_URL}}
    CYBERSOURCE_SECURITY_KEY: {{ cybersource_creds.data.security_key }}
    CYBERSOURCE_TRANSACTION_KEY: __vault__::secret-xpro/cybersource>data>transaction_key
    CYBERSOURCE_WSDL_URL: {{ env_data.CYBERSOURCE_WSDL_URL }}
    CYBERSOURCE_INQUIRY_LOG_NACL_ENCRYPTION_KEY: __vault__::secret-xpro/cybersource>data>inquiry_log_nacl_encryption_key
    {% set pg_creds = salt.vault.cached_read('postgres-xpro/creds/app', cache_prefix='heroku-mitxpro') %}
    DATABASE_URL: postgres://{{ pg_creds.data.username }}:{{ pg_creds.data.password }}@{{ rds_endpoint }}/mitxpro
    {% if env_data.env_name == 'production' %}
    CERTIFICATE_CREATION_DELAY_IN_HOURS: 48
    HIREFIRE_TOKEN: __vault__::secret-xpro/hirefire>data>token
    {% endif %}
    DEFERRAL_REQUEST_WORKSHEET_ID: __vault__::secret-xpro/google-sheets>data>deferral_worksheet_id
    DIGITAL_CREDENTIALS_ISSUER_ID: __vault__::secret-xpro/digital-credentials>data>issuer_id
    DIGITAL_CREDENTIALS_OAUTH2_CLIENT_ID: __vault__::secret-xpro/digital-credentials>data>oauth2_client_id
    DIGITAL_CREDENTIALS_SUPPORTED_RUNS: {{ env_data.DIGITAL_CREDENTIALS_SUPPORTED_RUNS }}
    DIGITAL_CREDENTIALS_VERIFICATION_METHOD: __vault__::secret-xpro/digital-credentials>data>verification_method
    DRIVE_OUTPUT_FOLDER_ID: __vault__::secret-xpro/google-sheets>data>folder_id
    DRIVE_SERVICE_ACCOUNT_CREDS: __vault__::secret-xpro/google-sheets>data>service_account_creds
    DRIVE_SHARED_ID: __vault__::secret-xpro/google-sheets>data>drive_shared_id
    ENABLE_ORDER_RECEIPTS: {{ env_data.ENABLE_ORDER_RECEIPTS }}
    ENROLLMENT_CHANGE_SHEET_ID: __vault__::secret-xpro/google-sheets>data>enroll_change_sheet_id
    FEATURE_COUPON_SHEETS: True
    FEATURE_COUPON_SHEETS_TRACK_REQUESTER: True
    {% if env_data.env_name == 'rc' %}
    FEATURE_DIGITAL_CREDENTIALS: True
    {% endif %}
    GA_TRACKING_ID: {{ env_data.GOOGLE_TRACKING_ID }}
    GTM_TRACKING_ID: {{ env_data.GOOGLE_TAG_MANAGER_ID }}
    HUBSPOT_FOOTER_FORM_GUID: {{ env_data.HUBSPOT_FOOTER_FORM_GUID }}
    HUBSPOT_NEW_COURSES_FORM_GUID: {{ env_data.HUBSPOT_NEW_COURSES_FORM_GUID }}
    HUBSPOT_PIPELINE_ID: '75e28846-ad0d-4be2-a027-5e1da6590b98'
    HUBSPOT_PORTAL_ID: {{ env_data.HUBSPOT_PORTAL_ID }}
    LOGOUT_REDIRECT_URL: {{ env_data.logout_redirect_url }}
    MAILGUN_KEY: __vault__::secret-global/data/mailgun>data>api_key
    MAILGUN_FROM_EMAIL: {{ env_data.MAILGUN_FROM_EMAIL }}
    MAILGUN_SENDER_DOMAIN: {{ env_data.MAILGUN_SENDER_DOMAIN }}
    MITOL_DIGITAL_CREDENTIALS_AUTH_TYPE: code
    MITOL_DIGITAL_CREDENTIALS_DEEP_LINK_URL: dccrequest://request
    MITOL_DIGITAL_CREDENTIALS_HMAC_SECRET: __vault__::secret-xpro/digital-credentials>data>hmac_secret
    MITOL_DIGITAL_CREDENTIALS_VERIFY_SERVICE_BASE_URL: __vault__::secret-xpro/digital-credentials>data>sign_and_verify_url
    MITOL_HUBSPOT_API_PRIVATE_TOKEN: __vault__::secret-xpro/hubspot>data>api_private_token
    MITOL_HUBSPOT_API_ID_PREFIX: {{ env_data.HUBSPOT_ID_PREFIX }}
    MITXPRO_ADMIN_EMAIL: 'cuddle-bunnies@mit.edu'
    MITXPRO_BASE_URL: {{ env_data.MITXPRO_BASE_URL }}
    MITXPRO_DB_CONN_MAX_AGE: 0
    MITXPRO_DB_DISABLE_SSL: True    # pgbouncer buildpack uses stunnel to handle encryption
    MITXPRO_EMAIL_HOST: {{ smtp_config.data.relay_host }}
    MITXPRO_EMAIL_PASSWORD: {{ smtp_config.data.relay_password }}
    MITXPRO_EMAIL_PORT: {{ smtp_config.data.relay_port }}
    MITXPRO_EMAIL_TLS: True
    MITXPRO_EMAIL_USER: {{ smtp_config.data.relay_username }}
    MITXPRO_ENVIRONMENT: {{ env_data.env_name }}
    MITXPRO_FROM_EMAIL: 'MIT xPRO <support@xpro.mit.edu>'
    MITXPRO_LOG_LEVEL: {{ env_data.app_log_level }}
    MITXPRO_OAUTH_PROVIDER: 'mitxpro-oauth2'
    MITXPRO_REGISTRATION_ACCESS_TOKEN:  __vault__::secret-xpro/openedx>data>registration_access_token
    MITXPRO_REPLY_TO_ADDRESS: 'MIT xPRO <support@xpro.mit.edu>'
    MITXPRO_SECURE_SSL_REDIRECT: True
    MITXPRO_SECURE_SSL_HOST: {{ env_data.MITXPRO_SECURE_SSL_HOST }}
    MITXPRO_SUPPORT_EMAIL: {{ smtp_config.data.support_email }}
    MITXPRO_USE_S3: True
    NODE_MODULES_CACHE: False
    OAUTH2_PROVIDER_ALLOWED_REDIRECT_URI_SCHEMES: http,https,dccrequest  # this adds 'dccrequest' to the defaults and should match the scheme in MITOL_DIGITAL_CREDENTIALS_DEEP_LINK_URL
    OPENEDX_API_BASE_URL: {{ env_data.OPENEDX_API_BASE_URL}}
    OPENEDX_API_CLIENT_ID: __vault__::secret-xpro/openedx-api-client>data>client_id
    OPENEDX_API_CLIENT_SECRET: __vault__::secret-xpro/openedx-api-client>data>client_secret
    OPENEDX_API_KEY: __vault__::secret-xpro/openedx>data>edxapp_api_key
    # This can be removed once PR#1314 is in production
    OPENEDX_GRADES_API_TOKEN:  __vault__::secret-xpro/openedx>data>grades_api_token
    OPENEDX_OAUTH_APP_NAME: 'edx-oauth-app'
    # This replaces OPENEDX_GRADES_API_TOKEN and is tied to xpro-grades-api user in openedx
    OPENEDX_SERVICE_WORKER_API_TOKEN: __vault__::secret-xpro/openedx>data>service_worker_api_token
    OPENEDX_SERVICE_WORKER_USERNAME: xpro-service-worker-api
    PGBOUNCER_DEFAULT_POOL_SIZE: 50
    PGBOUNCER_MIN_POOL_SIZE: 5
    RECAPTCHA_SITE_KEY: __vault__::secret-xpro/recaptcha>data>site_key
    RECAPTCHA_SECRET_KEY: __vault__::secret-xpro/recaptcha>data>secret_key
    REFUND_REQUEST_WORKSHEET_ID: __vault__::secret-xpro/google-sheets>data>refund_worksheet_id
    SECRET_KEY: __vault__::secret-xpro/django>data>secret-key
    SENTRY_DSN: __vault__::secret-xpro/sentry>data>dsn
    SENTRY_LOG_LEVEL: {{ env_data.sentry_log_level }}
    SHEETS_ADMIN_EMAILS: {{ salt.sdb.get('sdb://consul/xpro/' ~ environment ~'/sheets-admin-emails') }}
    SHEETS_DATE_TIMEZONE: America/New_York
    SHEETS_MONITORING_FREQUENCY: {{ env_data.SHEETS_MONITORING_FREQUENCY }}
    SHEETS_DEFERRAL_FIRST_ROW: {{ env_data.SHEETS_DEFERRAL_FIRST_ROW }}
    SHEETS_REFUND_FIRST_ROW: {{ env_data.SHEETS_REFUND_FIRST_ROW }}
    SHEETS_REFUND_PROCESSOR_COL: {{ env_data.SHEETS_REFUND_PROCESSOR_COL }}
    SHEETS_REFUND_COMPLETED_DATE_COL: {{ env_data.SHEETS_REFUND_COMPLETED_DATE_COL }}
    SHEETS_REFUND_ERROR_COL: {{ env_data.SHEETS_REFUND_ERROR_COL }}
    SHEETS_REFUND_SKIP_ROW_COL: {{ env_data.SHEETS_REFUND_SKIP_ROW_COL }}
    SHEETS_TASK_OFFSET: 120
    SHOW_UNREDEEMED_COUPON_ON_DASHBOARD: True
    SITE_NAME: "MIT xPRO"
    STATUS_TOKEN: __vault__::secret-xpro/django>data>status-token
    USE_X_FORWARDED_HOST: True
    VOUCHER_COMPANY_ID: {{ env_data.VOUCHER_COMPANY_ID }}
    VOUCHER_DOMESTIC_AMOUNT_KEY: __vault__::secret-xpro/voucher-domestic>data>amount_key
    VOUCHER_DOMESTIC_COURSE_KEY: __vault__::secret-xpro/voucher-domestic>data>course_key
    VOUCHER_DOMESTIC_CREDITS_KEY: __vault__::secret-xpro/voucher-domestic>data>credits_key
    VOUCHER_DOMESTIC_DATE_KEY: __vault__::secret-xpro/voucher-domestic>data>date_key
    VOUCHER_DOMESTIC_DATES_KEY: __vault__::secret-xpro/voucher-domestic>data>dates_key
    VOUCHER_DOMESTIC_EMPLOYEE_ID_KEY: __vault__::secret-xpro/voucher-domestic>data>employee_id_key
    VOUCHER_DOMESTIC_EMPLOYEE_KEY: __vault__::secret-xpro/voucher-domestic>data>employee_key
    VOUCHER_DOMESTIC_KEY: __vault__::secret-xpro/voucher-domestic>data>key

schedule:
  refresh_{{ env_data.app_name }}_configs:
    days: 5
    function: state.sls
    args:
      - heroku.update_heroku_config
