{% set minion_id = salt.grains.get('id', '') %}
{% set environment = minion_id.split('-')[-1] %}
{% set rds_endpoint = salt.boto_rds.get_endpoint('production-apps-rds-postgres-mitxpro') %}

{% set env_dict = {
    'ci': {
      'app_name': 'xpro-ci',
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
      'HUBSPOT_FOOTER_FORM_GUID': 'ff810010-c33c-4e99-9285-32d283fbc816',
      'HUBSPOT_ID_PREFIX': 'xpro-ci',
      'HUBSPOT_NEW_COURSES_FORM_GUID': 'b9220dc1-4e48-4097-8539-9f2907f18b1e',
      'HUBSPOT_PORTAL_ID': 5890463,
      'MAILGUN_FROM_EMAIL': 'MIT xPRO <no-reply@xpro-ci-mail.odl.mit.edu>',
      'MAILGUN_SENDER_DOMAIN': 'xpro-ci-mail.odl.mit.edu',
      'MITXPRO_BASE_URL': 'https://xpro-ci.odl.mit.edu',
      'vault_env_path': 'rc-apps',
      'USE_X_FORWARDED_HOST': False,
      'VOUCHER_COMPANY_ID': 1
      },
    'rc': {
      'app_name': 'xpro-rc',
      'env_name': 'rc',
      'GOOGLE_TRACKING_ID': 'UA-5145472-40',
      'GOOGLE_TAG_MANAGER_ID': 'GTM-KJHRV6K',
      'release_branch': 'release-candidate',
      'app_log_level': 'INFO',
      'sentry_log_level': 'WARN',
      'logout_redirect_url': 'https://courses-rc.xpro.mit.edu/logout',
      'OPENEDX_API_BASE_URL': 'https://courses-rc.xpro.mit.edu',
      'openedx_environment': 'mitxpro-qa',
      'CYBERSOURCE_SECURE_ACCEPTANCE_URL': 'https://testsecureacceptance.cybersource.com/pay',
      'CYBERSOURCE_WSDL_URL': 'https://ics2wstest.ic3.com/commerce/1.x/transactionProcessor/CyberSourceTransaction_1.154.wsdl',
      'HUBSPOT_FOOTER_FORM_GUID': 'ff810010-c33c-4e99-9285-32d283fbc816',
      'HUBSPOT_ID_PREFIX': 'xpro-rc',
      'HUBSPOT_NEW_COURSES_FORM_GUID': 'b9220dc1-4e48-4097-8539-9f2907f18b1e',
      'HUBSPOT_PORTAL_ID': 5890463,
      'MAILGUN_FROM_EMAIL': 'MIT xPRO <no-reply@xpro-rc-mail.odl.mit.edu>',
      'MAILGUN_SENDER_DOMAIN': 'xpro-rc-mail.odl.mit.edu',
      'MITXPRO_BASE_URL': 'https://xpro-rc.odl.mit.edu',
      'vault_env_path': 'rc-apps',
      'USE_X_FORWARDED_HOST': False,
      'VOUCHER_COMPANY_ID': 1
      },
    'production': {
      'app_name': 'xpro-production',
      'env_name': 'production',
      'GOOGLE_TRACKING_ID': 'UA-5145472-38',
      'GOOGLE_TAG_MANAGER_ID': 'GTM-KG4FR7J',
      'release_branch': 'release',
      'app_log_level': 'INFO',
      'sentry_log_level': 'WARN',
      'logout_redirect_url': 'https://courses.xpro.mit.edu/logout',
      'OPENEDX_API_BASE_URL': 'https://courses.xpro.mit.edu',
      'openedx_environment': 'mitxpro-production',
      'CYBERSOURCE_SECURE_ACCEPTANCE_URL': 'https://secureacceptance.cybersource.com/pay',
      'CYBERSOURCE_WSDL_URL': 'https://ics2wsa.ic3.com/commerce/1.x/transactionProcessor/CyberSourceTransaction_1.154.wsdl',
      'HUBSPOT_FOOTER_FORM_GUID': '6f7e46ec-f757-43a4-b109-597210df0f75',
      'HUBSPOT_ID_PREFIX': 'xpro',
      'HUBSPOT_NEW_COURSES_FORM_GUID': 'ad5d54e5-5ca9-4255-9c17-fa222e0a9b82',
      'HUBSPOT_PORTAL_ID': 4994459,
      'MAILGUN_FROM_EMAIL': 'MIT xPRO <no-reply@xpro-mail.odl.mit.edu>',
      'MAILGUN_SENDER_DOMAIN': 'xpro-mail.odl.mit.edu',
      'MITXPRO_BASE_URL': 'https://xpro.mit.edu',
      'vault_env_path': 'production-apps',
      'USE_X_FORWARDED_HOST': True,
      'VOUCHER_COMPANY_ID': 4
      }
} %}
{% set env_data = env_dict[environment] %}
{% set business_unit = 'mitxpro' %}
{% set pg_creds = salt.vault.cached_read('postgres-production-apps-mitxpro/creds/mitxpro', cache_prefix='heroku-mitxpro') %}
{% set cybersource_creds = salt.vault.read('secret-' ~ business_unit ~ '/' ~ env_data.vault_env_path ~ '/cybersource') %}

proxy:
  proxytype: heroku

heroku:
  app_name: {{ env_data.app_name }}
  api_key: __vault__::secret-operations/global/heroku/api_key>data>value
  config_vars:
    AWS_ACCESS_KEY_ID:  __vault__:cache:aws-mitx/creds/read-write-delete-xpro-app-{{ env_data.env_name }}>data>access_key
    AWS_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/read-write-delete-xpro-app-{{ env_data.env_name }}>data>secret_key
    AWS_STORAGE_BUCKET_NAME: 'xpro-app-{{ env_data.env_name }}'
    COUPON_REQUEST_SHEET_ID: __vault__::secret-{{ business_unit }}/{{ environment }}/google-sheets-coupon-integration>data>sheet_id
    CYBERSOURCE_ACCESS_KEY: {{ cybersource_creds.data.access_key }}
    CYBERSOURCE_MERCHANT_ID: 'mit_odl_xpro'
    CYBERSOURCE_PROFILE_ID: {{ cybersource_creds.data.profile_id }}
    CYBERSOURCE_REFERENCE_PREFIX: xpro-{{ env_data.env_name }}
    CYBERSOURCE_SECURE_ACCEPTANCE_URL: {{ env_data.CYBERSOURCE_SECURE_ACCEPTANCE_URL}}
    CYBERSOURCE_SECURITY_KEY: {{ cybersource_creds.data.security_key }}
    CYBERSOURCE_TRANSACTION_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/cybersource-transction-key>data>value
    CYBERSOURCE_WSDL_URL: {{ env_data.CYBERSOURCE_WSDL_URL }}
    CYBERSOURCE_INQUIRY_LOG_NACL_ENCRYPTION_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/cybersource-inquiry-encryption-key>data>public_key
    {% if env_data.env_name == 'production' %}
    DATABASE_URL: postgres://{{ pg_creds.data.username }}:{{ pg_creds.data.password }}@{{ rds_endpoint }}/mitxpro
    {% endif %}
    DRIVE_OUTPUT_FOLDER_ID: __vault__::secret-{{ business_unit }}/{{ environment }}/google-sheets-coupon-integration>data>folder_id
    DRIVE_SERVICE_ACCOUNT_CREDS: __vault__::secret-{{ business_unit }}/{{ environment }}/google-sheets-coupon-integration>data>service_account_creds
    DRIVE_SHARED_ID: __vault__::secret-{{ business_unit }}/{{ environment }}/google-sheets-coupon-integration>data>drive_shared_id
    GA_TRACKING_ID: {{ env_data.GOOGLE_TRACKING_ID }}
    GTM_TRACKING_ID: {{ env_data.GOOGLE_TAG_MANAGER_ID }}
    HUBSPOT_API_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/hubspot-api-key>data>value
    HUBSPOT_FOOTER_FORM_GUID: {{ env_data.HUBSPOT_FOOTER_FORM_GUID }}
    HUBSPOT_ID_PREFIX: {{ env_data.HUBSPOT_ID_PREFIX }}
    HUBSPOT_NEW_COURSES_FORM_GUID: {{ env_data.HUBSPOT_NEW_COURSES_FORM_GUID }}
    HUBSPOT_PORTAL_ID: {{ env_data.HUBSPOT_PORTAL_ID }}
    LOGOUT_REDIRECT_URL: {{ env_data.logout_redirect_url }}
    MAILGUN_KEY: __vault__::secret-operations/global/mailgun-api-key>data>value
    MAILGUN_FROM_EMAIL: {{ env_data.MAILGUN_FROM_EMAIL }}
    MAILGUN_SENDER_DOMAIN: {{ env_data.MAILGUN_SENDER_DOMAIN }}
    MITXPRO_ADMIN_EMAIL: 'cuddle-bunnies@mit.edu'
    MITXPRO_BASE_URL: {{ env_data.MITXPRO_BASE_URL }}
    MITXPRO_DB_CONN_MAX_AGE: 0
    MITXPRO_DB_DISABLE_SSL: True    # pgbouncer buildpack uses stunnel to handle encryption
    MITXPRO_EMAIL_HOST: __vault__::secret-operations/global/mit-smtp>data>relay_host
    MITXPRO_EMAIL_PASSWORD: __vault__::secret-operations/global/mit-smtp>data>relay_password
    MITXPRO_EMAIL_PORT: 587
    MITXPRO_EMAIL_TLS: True
    MITXPRO_EMAIL_USER: __vault__::secret-operations/global/mit-smtp>data>relay_username
    MITXPRO_ENVIRONMENT: {{ env_data.env_name }}
    MITXPRO_FROM_EMAIL: 'MIT xPRO <xpro@mit.edu>'
    MITXPRO_LOG_LEVEL: {{ env_data.app_log_level }}
    MITXPRO_OAUTH_PROVIDER: 'mitxpro-oauth2'
    MITXPRO_REGISTRATION_ACCESS_TOKEN:  __vault__:gen_if_missing:secret-{{ business_unit }}/{{ env_data.openedx_environment }}/xpro-registration-access-token>data>value
    MITXPRO_REPLY_TO_ADDRESS: 'MIT xPRO <xpro@mit.edu>'
    MITXPRO_SECURE_SSL_REDIRECT: True
    MITXPRO_SUPPORT_EMAIL: 'xpro@mit.edu'
    MITXPRO_USE_S3: True
    NODE_MODULES_CACHE: False
    OPENEDX_API_BASE_URL: {{ env_data.OPENEDX_API_BASE_URL}}
    OPENEDX_API_CLIENT_ID: __vault__::secret-{{ business_unit }}/{{ environment }}/openedx-api-client>data>client-id
    OPENEDX_API_CLIENT_SECRET: __vault__::secret-{{ business_unit }}/{{ environment }}/openedx-api-client>data>client-secret
    OPENEDX_API_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ env_data.openedx_environment }}/edx-api-key>data>value
    OPENEDX_GRADES_API_TOKEN:  __vault__::secret-{{ business_unit }}/{{ environment }}/openedx-grades-api-token>data>value
    OPENEDX_OAUTH_APP_NAME: 'edx-oauth-app'
    PGBOUNCER_DEFAULT_POOL_SIZE: 50
    PGBOUNCER_MIN_POOL_SIZE: 5
    RECAPTCHA_SITE_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/recaptcha-keys>data>site_key
    RECAPTCHA_SECRET_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/recaptcha-keys>data>secret_key
    SECRET_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/django-secret-key>data>value
    SENTRY_DSN: __vault__::secret-operations/global/xpro/sentry-dsn>data>value
    SENTRY_LOG_LEVEL: {{ env_data.sentry_log_level }}
    SITE_NAME: "MIT xPRO"
    STATUS_TOKEN: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/django-status-token>data>value
    USE_X_FORWARDED_HOST: {{ env_data.USE_X_FORWARDED_HOST }}
    VOUCHER_COMPANY_ID: {{ env_data.VOUCHER_COMPANY_ID }}
    VOUCHER_DOMESTIC_AMOUNT_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/voucher-domestic>data>amount_key
    VOUCHER_DOMESTIC_COURSE_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/voucher-domestic>data>course_key
    VOUCHER_DOMESTIC_CREDITS_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/voucher-domestic>data>credits_key
    VOUCHER_DOMESTIC_DATE_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/voucher-domestic>data>date_key
    VOUCHER_DOMESTIC_DATES_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/voucher-domestic>data>dates_key
    VOUCHER_DOMESTIC_EMPLOYEE_ID_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/voucher-domestic>data>employee_id_key
    VOUCHER_DOMESTIC_EMPLOYEE_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/voucher-domestic>data>employee_key
    VOUCHER_DOMESTIC_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/voucher-domestic>data>key
    VOUCHER_INTERNATIONAL_AMOUNT_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/voucher-international>data>amount_key
    VOUCHER_INTERNATIONAL_COURSE_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/voucher-international>data>course_key
    VOUCHER_INTERNATIONAL_COURSE_NAME_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/voucher-international>data>course_name_key
    VOUCHER_INTERNATIONAL_COURSE_NUMBER_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/voucher-international>data>course_number_key
    VOUCHER_INTERNATIONAL_DATES_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/voucher-international>data>dates_key
    VOUCHER_INTERNATIONAL_EMPLOYEE_ID_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/voucher-international>data>employee_id_key
    VOUCHER_INTERNATIONAL_EMPLOYEE_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/voucher-international>data>employee_key
    VOUCHER_INTERNATIONAL_PROGRAM_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/voucher-international>data>program_key
    VOUCHER_INTERNATIONAL_SCHOOL_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/voucher-international>data>school_key

schedule:
  refresh_{{ env_data.app_name }}_configs:
    days: 5
    function: state.sls
    args:
      - heroku.update_heroku_config
