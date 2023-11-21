{% set minion_id = salt.grains.get('id', '') %}
{% set environment = minion_id.split('-')[-1] %}

{% set env_dict = {
    'rc': {
      'app_name': 'bootcamp-ecommerce-rc',
      'aws_env': 'qa',
      'env_name': 'rc',
      'ALLOWED_HOSTS': ["bootcamp-rc.odl.mit.edu"],
      'BOOTCAMP_ECOMMERCE_BASE_URL': 'https://bootcamp-rc.odl.mit.edu',
      'BOOTCAMP_LOG_LEVEL': 'INFO',
      'BOOTCAMP_SUPPORT_EMAIL': 'bootcamp-support@mit.edu',
      'CYBERSOURCE_SECURE_ACCEPTANCE_URL': 'https://testsecureacceptance.cybersource.com/pay',
      'CYBERSOURCE_REFERENCE_PREFIX': 'rc',
      'CYBERSOURCE_WSDL_URL': 'https://ics2wstest.ic3.com/commerce/1.x/transactionProcessor/CyberSourceTransaction_1.154.wsdl',
      'EDXORG_BASE_URL': 'https://courses.stage.edx.org',
      'FEATURE_NOVOED_INTEGRATION': True,
      'GA_TRACKING_ID': 'UA-5145472-19',
      'GTM_TRACKING_ID': 'GTM-NZT8SRC',
      'HUBSPOT_API_ID_PREFIX': 'bootcamp-rc',
      'HUBSPOT_PORTAL_ID': '23263862',
      'HUBSPOT_FOOTER_FORM_GUID': 'be317df4-ed94-4d42-bfb9-01adec557d8f',
      'JOBMA_BASE_URL': 'https://dev.jobma.com', 
      'MAILGUN_SENDER_DOMAIN': 'mail-rc.bootcamp.odl.mit.edu',
      'NOVOED_BASE_URL': 'https://mitstaging.novoed.com',
      'NOVOED_SAML_DEBUG': True,
      'NOVOED_SAML_LOGIN_URL': 'https://app.novoed.com/saml/sso?provider=mitstaging',
      'SITE_NAME': 'MIT Bootcamps RC',
      },
    'production': {
      'app_name': 'bootcamp-ecommerce',
      'aws_env': 'production',
      'env_name': 'production',
      'ALLOWED_HOSTS': ["bootcamp.mit.edu", "bootcamps.mit.edu", "bootcamp.odl.mit.edu"],
      'BOOTCAMP_ECOMMERCE_BASE_URL': 'https://bootcamp.odl.mit.edu',
      'BOOTCAMP_LOG_LEVEL': 'INFO',
      'BOOTCAMP_SUPPORT_EMAIL': 'bootcamp@mit.edu',
      'CYBERSOURCE_SECURE_ACCEPTANCE_URL': 'https://secureacceptance.cybersource.com/pay',
      'CYBERSOURCE_REFERENCE_PREFIX': 'prod',
      'CYBERSOURCE_WSDL_URL': 'https://ics2wsa.ic3.com/commerce/1.x/transactionProcessor/CyberSourceTransaction_1.154.wsdl',
      'EDXORG_BASE_URL': 'https://courses.edx.org',
      'FEATURE_NOVOED_INTEGRATION': True,
      'GA_TRACKING_ID': 'UA-5145472-18',
      'GTM_TRACKING_ID': 'GTM-TFSZHVB',
      'HUBSPOT_API_ID_PREFIX': 'bootcamp',
      'HUBSPOT_PORTAL_ID': '6119748',
      'HUBSPOT_FOOTER_FORM_GUID': '2d798908-c195-4c0c-b075-a10b0c1b08f3',
      'JOBMA_BASE_URL': 'https://www.jobma.com',
      'MAILGUN_SENDER_DOMAIN': 'mail.bootcamp.odl.mit.edu',
      'NOVOED_BASE_URL': 'https://mitbootcamps.novoed.com',
      'NOVOED_SAML_DEBUG': False,
      'NOVOED_SAML_LOGIN_URL': 'https://app.novoed.com/saml/sso?provider=mitbootcamps',
      'SITE_NAME': 'MIT Bootcamps',
      }
} %}
{% set env_data = env_dict[environment] %}
{% set cybersource_creds = salt.vault.read('secret-bootcamps/data/cybersource').data.data %}
{% set jobma = salt.vault.read('secret-bootcamps/data/jobma').data.data %}
{% set mit_smtp = salt.vault.read('secret-global/data/mit-smtp').data.data %}

proxy:
  proxytype: heroku

heroku:
  app_name: {{ env_data.app_name }}
  api_key: __vault__::secret-global/data/heroku>data>data>mitx_devops_api_key
  config_vars:
    ALLOWED_HOSTS: '{{ env_data.ALLOWED_HOSTS|tojson }}'
    AWS_ACCESS_KEY_ID:  __vault__:cache:aws-mitx/creds/bootcamps-app>data>access_key
    AWS_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/bootcamps-app>data>secret_key
    AWS_STORAGE_BUCKET_NAME: 'ol-bootcamps-app-{{ env_data.aws_env }}'
    BOOTCAMP_ADMIN_EMAIL: cuddle-bunnies@mit.edu
    BOOTCAMP_DB_DISABLE_SSL: True
    BOOTCAMP_ECOMMERCE_BASE_URL: {{ env_data.BOOTCAMP_ECOMMERCE_BASE_URL }}
    BOOTCAMP_EMAIL_HOST: {{ mit_smtp.relay_host }}
    BOOTCAMP_EMAIL_PASSWORD: {{ mit_smtp.relay_password }}
    BOOTCAMP_EMAIL_PORT: 587
    BOOTCAMP_EMAIL_TLS: True
    BOOTCAMP_EMAIL_USER: {{ mit_smtp.relay_username }}
    BOOTCAMP_ENVIRONMENT: {{ env_data.env_name }}
    BOOTCAMP_LOG_LEVEL: {{ env_data.BOOTCAMP_LOG_LEVEL }}
    BOOTCAMP_REPLY_TO_ADDRESS: 'MIT Bootcamps <bootcamps-support@mit.edu>'
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
    {% set rds_endpoint = salt.boto_rds.get_endpoint('bootcamps-db-applications-{env}'.format(env=env_data.aws_env)) %}
    {% set pg_creds = salt.vault.cached_read('postgres-bootcamps/creds/app', cache_prefix='heroku-bootcamp') %}
    DATABASE_URL: postgres://{{ pg_creds.data.username }}:{{ pg_creds.data.password }}@{{ rds_endpoint }}/bootcamps
    {% if env_data.env_name == 'production' %}
    BOOTCAMP_ECOMMERCE_SAML_BASE_URL: https://bootcamps.mit.edu
    HIREFIRE_TOKEN: __vault__::secret-bootcamps/data/hirefire>data>data>token
    SESSION_ENGINE_BACKEND: cache
    USE_X_FORWARDED_HOST: True
    {% endif %}
    EDXORG_BASE_URL: {{ env_data.EDXORG_BASE_URL }}
    EDXORG_CLIENT_ID: __vault__::secret-bootcamps/data/edx>data>data>client_id
    EDXORG_CLIENT_SECRET: __vault__::secret-bootcamps/data/edx>data>data>client_secret
    ENABLE_STUNNEL_AMAZON_RDS_FIX: true
    FEATURE_ENABLE_CERTIFICATE_USER_VIEW: True
    FEATURE_SOCIAL_AUTH_API: True
    FEATURE_CMS_HOME_PAGE: True
    FEATURE_NOVOED_INTEGRATION: {{ env_data.FEATURE_NOVOED_INTEGRATION }}
    GA_TRACKING_ID: {{ env_data.GA_TRACKING_ID }}
    GTM_TRACKING_ID: {{ env_data.GTM_TRACKING_ID }}
    HUBSPOT_PIPELINE_ID: '75e28846-ad0d-4be2-a027-5e1da6590b98'
    MITOL_HUBSPOT_API_PRIVATE_TOKEN: __vault__::secret-bootcamps/data/hubspot>data>data>api_private_token
    MITOL_HUBSPOT_API_ID_PREFIX: {{ env_data.HUBSPOT_API_ID_PREFIX }}
    HUBSPOT_PORTAL_ID: {{ env_data.HUBSPOT_PORTAL_ID }}
    HUBSPOT_FOOTER_FORM_GUID: {{ env_data.HUBSPOT_FOOTER_FORM_GUID }}
    JOBMA_ACCESS_TOKEN: {{ jobma.access_token }}
    JOBMA_BASE_URL: {{ env_data.JOBMA_BASE_URL }}
    JOBMA_WEBHOOK_ACCESS_TOKEN: {{ jobma.webhook_access_token }}
    JOBMA_LINK_EXPIRATION_DAYS: 13
    MAILGUN_FROM_EMAIL: 'MIT Bootcamps <no-reply@{{ env_data.MAILGUN_SENDER_DOMAIN }}'
    MAILGUN_KEY: __vault__::secret-global/data/mailgun>data>data>api_key
    MAILGUN_SENDER_DOMAIN: {{ env_data.MAILGUN_SENDER_DOMAIN }}
    MAILGUN_URL: https://api.mailgun.net/v3/{{ env_data.MAILGUN_SENDER_DOMAIN }}
    MAX_FILE_UPLOAD_MB: 10
    NEW_RELIC_APP_NAME: Bootcamp {{ env_data.env_name }}
    NODE_MODULES_CACHE: False
    NOVOED_API_BASE_URL: https://api.novoed.com/
    NOVOED_API_KEY: __vault__::secret-bootcamps/data/novoed>data>data>api_key
    NOVOED_API_SECRET: __vault__::secret-bootcamps/data/novoed>data>data>api_secret
    NOVOED_BASE_URL: {{ env_data.NOVOED_BASE_URL }}
    NOVOED_SAML_DEBUG: {{ env_data.NOVOED_SAML_DEBUG }}
    NOVOED_SAML_KEY: __vault__::secret-bootcamps/data/novoed>data>data>saml_key
    NOVOED_SAML_CERT: __vault__::secret-bootcamps/data/novoed>data>data>saml_cert
    NOVOED_SAML_LOGIN_URL: {{ env_data.NOVOED_SAML_LOGIN_URL }}
    PGBOUNCER_DEFAULT_POOL_SIZE: 50
    PGBOUNCER_MIN_POOL_SIZE: 5
    RECAPTCHA_SITE_KEY: __vault__::secret-bootcamps/data/recaptcha>data>data>site_key
    RECAPTCHA_SECRET_KEY: __vault__::secret-bootcamps/data/recaptcha>data>data>secret_key
    SECRET_KEY: __vault__::secret-bootcamps/data/django>data>data>secret_key
    SENTRY_DSN: __vault__::secret-bootcamps/data/sentry>data>data>dsn
    SITE_NAME: {{ env_data.SITE_NAME }}
    STATUS_TOKEN: __vault__::secret-bootcamps/data/django>data>data>status_token
    ZENDESK_HELP_WIDGET_ENABLED: True
