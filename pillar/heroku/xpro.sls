{% set minion_id = salt.grains.get('id', '') %}
{% set environment = minion_id.split('-')[-1] %}
{% set rds_endpoint = salt.boto_rds.get_endpoint('production-apps-rds-postgres-mitxpro') %}

{% set env_dict = {
    'ci': {
      'env_name': 'ci',
      'GOOGLE_TRACKING_ID': 'GTM-KG4FR7J',
      'release_branch': 'master',
      'app_log_level': 'INFO',
      'sentry_log_level': 'WARN',
      'logout_redirect_url': 'https://xpro-qa-sandbox.mitx.mit.edu/logout',
      'OPENEDX_API_BASE_URL': 'https://xpro-qa-sandbox.mitx.mit.edu',
      'openedx_environment': 'mitxpro-sandbox',
      'CYBERSOURCE_SECURE_ACCEPTANCE_URL': 'https://testsecureacceptance.cybersource.com/pay',
      'CYBERSOURCE_WSDL_URL': 'https://ics2wstest.ic3.com/commerce/1.x/transactionProcessor/CyberSourceTransaction_1.154.wsdl',
      'MAILGUN_FROM_EMAIL': 'MIT xPRO <no-reply@xpro-ci-mail.odl.mit.edu>',
      'MAILGUN_SENDER_DOMAIN': 'xpro-ci-mail.odl.mit.edu',
      'MITXPRO_BASE_URL': 'https://xpro-{{ env_data.env_name}}.odl.mit.edu',
      'vault_env_path': 'rc-apps'
      },
    'rc': {
      'env_name': 'rc',
      'GOOGLE_TRACKING_ID': 'GTM-KG4FR7J',
      'release_branch': 'release-candidate',
      'app_log_level': 'INFO',
      'sentry_log_level': 'WARN',
      'logout_redirect_url': 'https://xpro-qa.mitx.mit.edu/logout',
      'OPENEDX_API_BASE_URL': 'https://xpro-qa.mitx.mit.edu',
      'openedx_environment': 'mitxpro-qa',
      'CYBERSOURCE_SECURE_ACCEPTANCE_URL': 'https://testsecureacceptance.cybersource.com/pay',
      'CYBERSOURCE_WSDL_URL': 'https://ics2wstest.ic3.com/commerce/1.x/transactionProcessor/CyberSourceTransaction_1.154.wsdl',
      'MAILGUN_FROM_EMAIL': 'MIT xPRO <no-reply@xpro-rc-mail.odl.mit.edu>',
      'MAILGUN_SENDER_DOMAIN': 'xpro-rc-mail.odl.mit.edu',
      'MITXPRO_BASE_URL': 'https://xpro-{{ env_data.env_name}}.odl.mit.edu',
      'vault_env_path': 'rc-apps'
      },
    'production': {
      'env_name': 'production',
      'GOOGLE_TRACKING_ID': 'GTM-KG4FR7J',
      'release_branch': 'release',
      'app_log_level': 'INFO',
      'sentry_log_level': 'WARN',
      'logout_redirect_url': 'https://xpro.mitx.mit.edu/logout',
      'OPENEDX_API_BASE_URL': 'https://xpro.mitx.mit.edu',
      'openedx_environment': 'mitxpro-production',
      'CYBERSOURCE_SECURE_ACCEPTANCE_URL': 'https://secureacceptance.cybersource.com/pay',
      'CYBERSOURCE_WSDL_URL':'https://ics2wsa.ic3.com/commerce/1.x/transactionProcessor/CyberSourceTransaction_1.154.wsdl',
      'MAILGUN_FROM_EMAIL': 'MIT xPRO <no-reply@xpro-mail.odl.mit.edu>',
      'MAILGUN_SENDER_DOMAIN': 'xpro-mail.odl.mit.edu',
      'MITXPRO_BASE_URL': 'https://xpro.mit.edu',
      'vault_env_path': 'production-apps'
      }
} %}
{% set env_data = env_dict[environment] %}
{% set business_unit = 'mitxpro' %}
{% set pg_creds = salt.vault.cached_read('postgres-production-apps-mitxpro/creds/mitxpro', cache_prefix='heroku-mitxpro') %}
{% set cybersource_creds = salt.vault.read('secret-' ~ business_unit ~ '/' ~ env_data.env_name.vault_env_path ~ '/cybersource') %}

proxy:
  proxytype: heroku

heroku:
  app_name: xpro-{{ env_data.env_name }}
  api_key: __vault__::secret-operations/global/heroku/api_key>data>value
  config_vars:
    AWS_ACCESS_KEY_ID:  __vault__:cache:aws-mitx/creds/read-write-xpro-app-{{ env_data.env_name }}>data>access_key
    AWS_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/read-write-xpro-app-{{ env_data.env_name }}>data>secret_key
    AWS_STORAGE_BUCKET_NAME: 'xpro-app-{{ env_data.env_name }}'
    CYBERSOURCE_ACCESS_KEY: {{ cybersource_creds.data.access_key }}
    CYBERSOURCE_MERCHANT_ID: 'mit_odl_xpro'
    CYBERSOURCE_PROFILE_ID: {{ cybersource_creds.data.profile_id }}
    CYBERSOURCE_REFERENCE_PREFIX: xpro-{{ env_data.env_name }}
    CYBERSOURCE_SECURE_ACCEPTANCE_URL: {{ env_data.CYBERSOURCE_SECURE_ACCEPTANCE_URL}}
    CYBERSOURCE_SECURITY_KEY: {{ cybersource_creds.data.security_key }}
    CYBERSOURCE_TRANSACTION_KEY: __vault__::secret-operations/{{ env_data.env_name.vault_env_path }}/{{ business_unit }}/cybersource-transction-key>data>value
    CYBERSOURCE_WSDL_URL: {{ env_data.CYBERSOURCE_WSDL_URL }}
    CYBERSOURCE_INQUIRY_LOG_NACL_ENCRYPTION_KEY: __vault__::secret-operations/{{ env_data.env_name.vault_env_path }}/{{ business_unit }}/cybersource-inquiry-encryption-key>data>public_key
    {% if env_data.env_name == 'production' %}
    DATABASE_URL: postgres://{{ pg_creds.data.username }}:{{ pg_creds.data.password }}@{{ rds_endpoint }}/mitxpro
    {% endif %}
    GA_TRACKING_ID: {{ env_data.GOOGLE_TRACKING_ID }}
    HUBSPOT_API_KEY: __vault__::secret-operations/{{ env_data.env_name.vault_env_path }}/{{ business_unit }}/hubspot-api-key>data>value
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
    MITXPRO_FROM_EMAIL: 'MIT xPro <xpro-{{ env_data.env_name }}-support@mit.edu>'
    MITXPRO_LOG_LEVEL: {{ env_data.app_log_level }}
    MITXPRO_OAUTH_PROVIDER: 'mitxpro-oauth2'
    MITXPRO_REGISTRATION_ACCESS_TOKEN:  __vault__:gen_if_missing:secret-{{ business_unit }}/{{ env_data.openedx_environment }}/xpro-registration-access-token>data>value
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
    RECAPTCHA_SITE_KEY: __vault__::secret-operations/{{ env_data.env_name.vault_env_path }}/{{ business_unit }}/recaptcha-keys>data>site_key
    RECAPTCHA_SECRET_KEY: __vault__::secret-operations/{{ env_data.env_name.vault_env_path }}/{{ business_unit }}/recaptcha-keys>secret_key
    SECRET_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/django-secret-key>data>value
    SENTRY_DSN: __vault__::secret-operations/global/xpro/sentry-dsn>data>value
    SENTRY_LOG_LEVEL: {{ env_data.sentry_log_level }}
    STATUS_TOKEN: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/django-status-token>data>value
    VOUCHER_COMPANY_ID: 1
    VOUCHER_DOMESTIC_AMOUNT_KEY: __vault__::secret-operations/{{ env_data.env_name.vault_env_path }}/{{ business_unit }}/voucher-domestic>data>amount_key
    VOUCHER_DOMESTIC_COURSE_KEY: __vault__::secret-operations/{{ env_data.env_name.vault_env_path }}/{{ business_unit }}/voucher-domestic>data>course_key
    VOUCHER_DOMESTIC_CREDITS_KEY: __vault__::secret-operations/{{ env_data.env_name.vault_env_path }}/{{ business_unit }}/voucher-domestic>data>credits_key
    VOUCHER_DOMESTIC_DATE_KEY: __vault__::secret-operations/{{ env_data.env_name.vault_env_path }}/{{ business_unit }}/voucher-domestic>data>date_key
    VOUCHER_DOMESTIC_DATES_KEY: __vault__::secret-operations/{{ env_data.env_name.vault_env_path }}/{{ business_unit }}/voucher-domestic>data>dates_key
    VOUCHER_DOMESTIC_EMPLOYEE_ID_KEY: __vault__::secret-operations/{{ env_data.env_name.vault_env_path }}/{{ business_unit }}/voucher-domestic>data>employee_id_key
    VOUCHER_DOMESTIC_EMPLOYEE_KEY: __vault__::secret-operations/{{ env_data.env_name.vault_env_path }}/{{ business_unit }}/voucher-domestic>data>employee_key
    VOUCHER_DOMESTIC_KEY: __vault__::secret-operations/{{ env_data.env_name.vault_env_path }}/{{ business_unit }}/voucher-domestic>data>key
    VOUCHER_INTERNATIONAL_AMOUNT_KEY: __vault__::secret-operations/{{ env_data.env_name.vault_env_path }}/{{ business_unit }}/voucher-international>data>amount_key
    VOUCHER_INTERNATIONAL_COURSE_KEY: __vault__::secret-operations/{{ env_data.env_name.vault_env_path }}/{{ business_unit }}/voucher-international>data>course_key
    VOUCHER_INTERNATIONAL_COURSE_NAME_KEY: __vault__::secret-operations/{{ env_data.env_name.vault_env_path }}/{{ business_unit }}/voucher-international>data>course_name_key
    VOUCHER_INTERNATIONAL_COURSE_NUMBER_KEY: __vault__::secret-operations/{{ env_data.env_name.vault_env_path }}/{{ business_unit }}/voucher-international>data>course_number_key
    VOUCHER_INTERNATIONAL_DATES_KEY: __vault__::secret-operations/{{ env_data.env_name.vault_env_path }}/{{ business_unit }}/voucher-international>data>dates_key
    VOUCHER_INTERNATIONAL_EMPLOYEE_ID_KEY: __vault__::secret-operations/{{ env_data.env_name.vault_env_path }}/{{ business_unit }}/voucher-international>data>employee_id_key
    VOUCHER_INTERNATIONAL_EMPLOYEE_KEY: __vault__::secret-operations/{{ env_data.env_name.vault_env_path }}/{{ business_unit }}/voucher-international>data>employee_key
    VOUCHER_INTERNATIONAL_PROGRAM_KEY: __vault__::secret-operations/{{ env_data.env_name.vault_env_path }}/{{ business_unit }}/voucher-international>data>program_key
    VOUCHER_INTERNATIONAL_SCHOOL_KEY: __vault__::secret-operations/{{ env_data.env_name.vault_env_path }}/{{ business_unit }}/voucher-international>data>school_key

