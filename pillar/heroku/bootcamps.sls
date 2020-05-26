{% set minion_id = salt.grains.get('id', '') %}
{% set environment = minion_id.split('-')[-1] %}
{% set rds_endpoint = salt.boto_rds.get_endpoint('bootcamps-rds-postgresql') %}

{% set env_dict = {
    'ci': {
      'app_name': 'bootcamp-ecommerce-ci',
      'env_name': 'ci',
      'BOOTCAMP_ADMISSION_BASE_URL': 'http://admissions-test.herokuapp.com',
      'BOOTCAMP_ECOMMERCE_BASE_URL': 'https://bootcamp-ecommerce-ci.herokuapp.com',
      'BOOTCAMP_LOG_LEVEL': 'INFO',
      'BOOTCAMP_SUPPORT_EMAIL': 'bootcamp-support@mit.edu',
      'CYBERSOURCE_SECURE_ACCEPTANCE_URL': 'https://testsecureacceptance.cybersource.com/pay',
      'CYBERSOURCE_REFERENCE_PREFIX': 'ci',
      'CYBERSOURCE_WSDL_URL': 'https://ics2wstest.ic3.com/commerce/1.x/transactionProcessor/CyberSourceTransaction_1.154.wsdl',
      'EDXORG_BASE_URL': 'https://micromasters.d.mitx.mit.edu',
      'GA_TRACKING_ID': 'UA-5145472-19',
      'GTM_TRACKING_ID': 'GTM-NZT8SRC',
      'MAILGUN_SENDER_DOMAIN': 'mail-rc.bootcamp.odl.mit.edu',
      'vault_env_path': 'rc-apps'
      },
    'rc': {
      'app_name': 'bootcamp-ecommerce-rc',
      'env_name': 'rc',
      'BOOTCAMP_ADMISSION_BASE_URL': 'http://admissions-test.herokuapp.com',
      'BOOTCAMP_ECOMMERCE_BASE_URL': 'http://bootcamp-rc.odl.mit.edu/',
      'BOOTCAMP_LOG_LEVEL': 'INFO',
      'BOOTCAMP_SUPPORT_EMAIL': 'bootcamp-support@mit.edu',
      'CYBERSOURCE_SECURE_ACCEPTANCE_URL': 'https://testsecureacceptance.cybersource.com/pay',
      'CYBERSOURCE_REFERENCE_PREFIX': 'rc',
      'CYBERSOURCE_WSDL_URL': 'https://ics2wstest.ic3.com/commerce/1.x/transactionProcessor/CyberSourceTransaction_1.154.wsdl',
      'EDXORG_BASE_URL': 'https://courses.stage.edx.org',
      'GA_TRACKING_ID': 'UA-5145472-19',
      'GTM_TRACKING_ID': 'GTM-NZT8SRC',
      'MAILGUN_SENDER_DOMAIN': 'mail-rc.bootcamp.odl.mit.edu',
      'vault_env_path': 'rc-apps'
      },
    'production': {
      'app_name': 'bootcamp-ecommerce',
      'env_name': 'production',
      'BOOTCAMP_ADMISSION_BASE_URL': 'http://admissions.herokuapp.com',
      'BOOTCAMP_ECOMMERCE_BASE_URL': 'https://bootcamp.odl.mit.edu/',
      'BOOTCAMP_LOG_LEVEL': 'INFO',
      'BOOTCAMP_SUPPORT_EMAIL': 'bootcamp@mit.edu',
      'CYBERSOURCE_SECURE_ACCEPTANCE_URL': 'https://secureacceptance.cybersource.com/pay',
      'CYBERSOURCE_REFERENCE_PREFIX': 'prod',
      'CYBERSOURCE_WSDL_URL': 'https://ics2wsa.ic3.com/commerce/1.x/transactionProcessor/CyberSourceTransaction_1.154.wsdl',
      'EDXORG_BASE_URL': 'https://courses.edx.org',
      'GA_TRACKING_ID': 'UA-5145472-18',
      'GTM_TRACKING_ID': 'GTM-NZT8SRC',
      'MAILGUN_SENDER_DOMAIN': 'mail.bootcamp.odl.mit.edu',
      'vault_env_path': 'production-apps'
      }
} %}
{% set env_data = env_dict[environment] %}
{% set business_unit = 'bootcamps' %}
{% set cybersource_creds = salt.vault.read('secret-' ~ business_unit ~ '/' ~ env_data.vault_env_path ~ '/cybersource').data %}
{% set jobma = salt.vault.read('secret-' ~ business_unit ~ '/' ~ env_data.vault_env_path ~ '/jobma').data %}

proxy:
  proxytype: heroku

heroku:
  app_name: {{ env_data.app_name }}
  api_key: __vault__::secret-operations/global/heroku/api_key>data>value
  config_vars:
    ALLOWED_HOSTS: '["*"]'
    AWS_ACCESS_KEY_ID:  __vault__:cache:aws-mitx/creds/read-write-delete-ol-bootcamps-app-{{ env_data.env_name }}>data>access_key
    AWS_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/read-write-delete-ol-bootcamps-app-{{ env_data.env_name }}>data>secret_key
    AWS_STORAGE_BUCKET_NAME: 'ol-bootcamps-app-{{ env_data.env_name }}'
    BOOTCAMP_ADMIN_EMAIL: cuddle-bunnies@mit.edu
    BOOTCAMP_ADMISSION_BASE_URL: {{ env_data.BOOTCAMP_ADMISSION_BASE_URL }}
    BOOTCAMP_ADMISSION_KEY: __vault__::secret-{{ business_unit }}/{{ env_data.vault_env_path }}/admissions/admission_key>data>value
    BOOTCAMP_DB_DISABLE_SSL: True
    BOOTCAMP_ECOMMERCE_BASE_URL: {{ env_data.BOOTCAMP_ECOMMERCE_BASE_URL }}
    BOOTCAMP_EMAIL_HOST: __vault__::secret-operations/global/mit-smtp>data>relay_host
    BOOTCAMP_EMAIL_PASSWORD: __vault__::secret-operations/global/mit-smtp>data>relay_password
    BOOTCAMP_EMAIL_PORT: 587
    BOOTCAMP_EMAIL_TLS: True
    BOOTCAMP_EMAIL_USER: mitxmail
    BOOTCAMP_ENVIRONMENT: {{ env_data.env_name }}
    BOOTCAMP_FROM_EMAIL: MIT Bootcamp <mitx-support@mit.edu>
    BOOTCAMP_LOG_LEVEL: {{ env_data.BOOTCAMP_LOG_LEVEL }}
    BOOTCAMP_SECURE_SSL_REDIRECT: True
    BOOTCAMP_SUPPORT_EMAIL: {{ env_data.BOOTCAMP_SUPPORT_EMAIL }}
    BOOTCAMP_USE_S3: True
    CYBERSOURCE_ACCESS_KEY: {{ cybersource_creds.access_key }}
    CYBERSOURCE_INQUIRY_LOG_NACL_ENCRYPTION_KEY: {{ cybersource_creds.inquiry_public_encryption_key }}
    CYBERSOURCE_MERCHANT_ID: 'mit_clb_bootcamp'
    CYBERSOURCE_PROFILE_ID: {{ cybersource_creds.profile_id }}
    CYBERSOURCE_REFERENCE_PREFIX: {{ env_data.CYBERSOURCE_REFERENCE_PREFIX }}
    CYBERSOURCE_SECURE_ACCEPTANCE_URL: {{ env_data.CYBERSOURCE_SECURE_ACCEPTANCE_URL}}
    CYBERSOURCE_SECURITY_KEY: {{ cybersource_creds.security_key }}
    CYBERSOURCE_TRANSACTION_KEY: {{ cybersource_creds.transaction_key }}
    CYBERSOURCE_WSDL_URL: {{ env_data.CYBERSOURCE_WSDL_URL }}
    {% if env_data.env_name == 'production' %}
    {% set pg_creds = salt.vault.cached_read('postgresql-bootcamps/creds/app', cache_prefix='heroku-bootcamp') %}
    BOOTCAMP_ECOMMERCE_EMAIL: __vault__::secret-{{ business_unit }}/production-apps/>cybersource>data>email
    DATABASE_URL: postgres://{{ pg_creds.data.username }}:{{ pg_creds.data.password }}@{{ rds_endpoint }}/bootcamp_ecommerce
    ENABLE_STUNNEL_AMAZON_RDS_FIX: true
    HIREFIRE_TOKEN: __vault__::secret-{{ business_unit }}/production-apps/hirefire_token>data>value
    {% endif %}
    EDXORG_BASE_URL: {{ env_data.EDXORG_BASE_URL }}
    EDXORG_CLIENT_ID: __vault__::secret-{{ business_unit }}/{{ env_data.env_name }}/edx>data>client_id
    EDXORG_CLIENT_SECRET: __vault__::secret-{{ business_unit }}/{{ env_data.env_name }}/edx>data>client_secret
    FEATURE_SOCIAL_AUTH_API: True
    GA_TRACKING_ID: {{ env_data.GA_TRACKING_ID }}
    GTM_TRACKING_ID: {{ env_data.GTM_TRACKING_ID }}
    HUBSPOT_API_KEY: __vault__::secret-{{ business_unit }}/{{ env_data.vault_env_path }}/hubspot>data>api_key
    HUBSPOT_ID_PREFIX: __vault__::secret-{{ business_unit }}/{{ env_data.vault_env_path }}/hubspot>data>id_prefix
    JOBMA_ACCESS_TOKEN: {{ jobma.access_token }}
    JOBMA_BASE_URL: {{ jobma.base_url }}
    JOBMA_WEBHOOK_ACCESS_TOKEN: {{ jobma.webhook_access_token }}
    MAILGUN_FROM_EMAIL: 'MIT Bootcamp <no-reply@{{ env_data.MAILGUN_SENDER_DOMAIN }}'
    MAILGUN_KEY: __vault__::secret-operations/global/mailgun-api-key>data>value
    MAILGUN_SENDER_DOMAIN: {{ env_data.MAILGUN_SENDER_DOMAIN }}
    MAILGUN_URL: https://api.mailgun.net/v3/{{ env_data.MAILGUN_SENDER_DOMAIN }}
    NEW_RELIC_APP_NAME: Bootcamp {{ env_data.env_name }}
    NODE_MODULES_CACHE: False
    PGBOUNCER_DEFAULT_POOL_SIZE: 50
    PGBOUNCER_MIN_POOL_SIZE: 5
    RECAPTCHA_SITE_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/recaptcha-keys>data>site_key
    RECAPTCHA_SECRET_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/recaptcha-keys>data>secret_key
    SECRET_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/django-secret-key>data>value
    SENTRY_DSN: __vault__::secret-operations/global/{{ business_unit}}/sentry-dsn>data>value
    STATUS_TOKEN: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/django-status-token>data>value
    ZENDESK_HELP_WIDGET_ENABLED: True
