{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set business_unit = salt.grains.get('business_unit', 'residential') %}
{% set purpose = salt.grains.get('purpose', 'current-residential-live') %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}
{% set purpose_prefix = purpose.rsplit('-', 1)[0] %}
{% set purpose_suffix = purpose.replace('-', '_') %}
{% set purpose_data = env_settings.environments[environment].purposes[purpose] %}
{% set LMS_DOMAIN = purpose_data.domains.lms %}

edx:
  ansible_vars:
    # E-Commerce Application

    ECOMMERCE_GIT_IDENTITY: !!null

    # depends upon Newrelic being enabled via COMMON_ENABLE_NEWRELIC
    # and a key being provided via NEWRELIC_LICENSE_KEY
    ECOMMERCE_NEWRELIC_APPNAME: "{{ COMMON_ENVIRONMENT }}-{{ COMMON_DEPLOYMENT }}-{{ ecommerce_service_name }}"
    ECOMMERCE_PIP_EXTRA_ARGS: "-i {{ COMMON_PYPI_MIRROR_URL }}"
    ECOMMERCE_NGINX_PORT: 18130
    ECOMMERCE_SSL_NGINX_PORT: 48130

    ECOMMERCE_MEMCACHE:
      - localhost:11211

    ECOMMERCE_DATABASE_NAME: ecommerce_{{ purpose_suffix }}
    ECOMMERCE_DATABASE_USER: __vault__:cache:mysql-{{ environment }}/creds/ecommerce-{{ purpose }}>data>username
    ECOMMERCE_DATABASE_PASSWORD: __vault__:cache:mysql-{{ environment }}/creds/ecommerce-{{ purpose }}>data>password
    ECOMMERCE_DATABASE_HOST: mysql.service.consul

    ECOMMERCE_VERSION: "master"
    ECOMMERCE_DJANGO_SETTINGS_MODULE: "ecommerce.settings.production"

    ECOMMERCE_SESSION_EXPIRE_AT_BROWSER_CLOSE: false
    ECOMMERCE_SECRET_KEY: __vault__:gen_if_missing:secret-residential/{{ environment }}/ecommerce/django-secret-key>data>value
    ECOMMERCE_EDX_API_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/edxapp-jwt-secret-key>data>value
    ECOMMERCE_ECOMMERCE_URL_ROOT: 'https://{{ purpose_data.domains.ecommerce }}'
    ECOMMERCE_LOGOUT_URL: '{{ ECOMMERCE_ECOMMERCE_URL_ROOT }}/logout/'
    ECOMMERCE_LMS_URL_ROOT: 'https://{{ purpose_data.domains.lms }}'
    ECOMMERCE_JWT_ALGORITHM: 'HS256'
    ECOMMERCE_JWT_VERIFY_EXPIRATION: true
    ECOMMERCE_JWT_DECODE_HANDLER: 'ecommerce.extensions.api.handlers.jwt_decode_handler'
    ECOMMERCE_JWT_ISSUERS:
      - ISSUER: "{{ COMMON_JWT_ISSUER }}"
        AUDIENCE: "{{ COMMON_JWT_AUDIENCE }}"
        SECRET_KEY: "{{ COMMON_JWT_SECRET_KEY }}"
      - ISSUER: 'ecommerce_worker'  # Must match the value of JWT_ISSUER configured for the ecommerce worker.
        AUDIENCE: "{{ COMMON_JWT_AUDIENCE }}"
        SECRET_KEY: "{{ COMMON_JWT_SECRET_KEY }}"

    ECOMMERCE_JWT_LEEWAY: 1

    # Used to automatically configure OAuth2 Client
    ECOMMERCE_SOCIAL_AUTH_EDX_OIDC_KEY: 'ecommerce-key'
    ECOMMERCE_SOCIAL_AUTH_EDX_OIDC_SECRET: 'ecommerce-secret'
    ECOMMERCE_SOCIAL_AUTH_REDIRECT_IS_HTTPS: false

    ECOMMERCE_OSCAR_FROM_EMAIL: 'oscar@example.com' # TODO: Determine appropriate value for this setting 2019-01-15 TMM

    # CyberSource related
    ECOMMERCE_CYBERSOURCE_PROFILE_ID: __vault__::secret-{{ business_unit }}/{{ environment }}/cybersource>data>profile_id
    ECOMMERCE_CYBERSOURCE_MERCHANT_ID: __vault__::secret-{{ business_unit }}/{{ environment }}/cybersource>data>merchant_id
    ECOMMERCE_CYBERSOURCE_ACCESS_KEY: __vault__::secret-{{ business_unit }}/{{ environment }}/cybersource>data>access_key
    ECOMMERCE_CYBERSOURCE_SECRET_KEY: __vault__::secret-{{ business_unit }}/{{ environment }}/cybersource>data>secret_key
    ECOMMERCE_CYBERSOURCE_SOP_ACCESS_KEY: __vault__::secret-{{ business_unit }}/{{ environment }}/cybersource>data>access_key
    ECOMMERCE_CYBERSOURCE_SOP_PROFILE_ID: __vault__::secret-{{ business_unit }}/{{ environment }}/cybersource>data>profile_id
    ECOMMERCE_CYBERSOURCE_SOP_SECRET_KEY: __vault__::secret-{{ business_unit }}/{{ environment }}/cybersource>data>secret_key
    ECOMMERCE_CYBERSOURCE_SOP_PAYMENT_PAGE_URL: 'https://testsecureacceptance.cybersource.com/silent/pay'
    ECOMMERCE_CYBERSOURCE_TRANSACTION_KEY: __vault__::secret-{{ business_unit }}/{{ environment }}/cybersource>data>transaction_key
    ECOMMERCE_CYBERSOURCE_PAYMENT_PAGE_URL: 'https://testsecureacceptance.cybersource.com/pay'
    ECOMMERCE_CYBERSOURCE_RECEIPT_PAGE_URL: '/checkout/receipt/'
    ECOMMERCE_CYBERSOURCE_CANCEL_PAGE_URL: '/checkout/cancel-checkout/'
    ECOMMERCE_CYBERSOURCE_SEND_LEVEL_2_3_DETAILS: true
    ECOMMERCE_CYBERSOURCE_SOAP_API_URL: 'https://ics2wstest.ic3.com/commerce/1.x/transactionProcessor/CyberSourceTransaction_1.140.wsdl'

    # PayPal
    ECOMMERCE_PAYPAL_MODE: 'sandbox'
    ECOMMERCE_PAYPAL_CLIENT_ID: 'SET-ME-PLEASE'
    ECOMMERCE_PAYPAL_CLIENT_SECRET: 'SET-ME-PLEASE'
    ECOMMERCE_PAYPAL_RECEIPT_URL: '/checkout/receipt/'
    ECOMMERCE_PAYPAL_CANCEL_URL: '/checkout/cancel-checkout/'
    ECOMMERCE_PAYPAL_ERROR_URL: '/checkout/error/'

    # Theming
    ECOMMERCE_PLATFORM_NAME: 'MIT xPRO'
    ECOMMERCE_THEME_SCSS: 'sass/themes/default.scss'
    ECOMMERCE_COMPREHENSIVE_THEME_DIRS:
      - '{{ THEMES_CODE_DIR }}/{{ ecommerce_service_name }}'
      - '{{ COMMON_APP_DIR }}/{{ ecommerce_service_name }}/{{ ecommerce_service_name }}/ecommerce/themes'

    ECOMMERCE_ENABLE_COMPREHENSIVE_THEMING: false
    ECOMMERCE_DEFAULT_SITE_THEME: !!null
    ECOMMERCE_STATICFILES_STORAGE: 'ecommerce.theming.storage.ThemeStorage'

    # E-Commerce Worker
    ECOMMERCE_WORKER_GIT_IDENTITY: !!null
    ECOMMERCE_WORKER_VERSION: 'master'

    # Requires that New Relic be enabled via COMMON_ENABLE_NEWRELIC, and that
    # a key be provided via NEWRELIC_LICENSE_KEY.
    ECOMMERCE_WORKER_NEWRELIC_APPNAME: '{{ COMMON_ENVIRONMENT }}-{{ COMMON_DEPLOYMENT }}-{{ ecommerce_worker_service_name }}'
    ECOMMERCE_WORKER_ENABLE_NEWRELIC_DISTRIBUTED_TRACING: false

    # CELERY
    ECOMMERCE_WORKER_BROKER_USERNAME: __vault__:cache:rabbitmq-{{ environment }}/creds/ecommerce>data>username
    ECOMMERCE_WORKER_BROKER_PASSWORD: __vault__:cache:rabbitmq-{{ environment }}/creds/ecommerce>data>password
    # Used as the default RabbitMQ IP.
    ECOMMERCE_WORKER_BROKER_HOST: nearest-rabbitmq.query.consul
    # Used as the default RabbitMQ port.
    ECOMMERCE_WORKER_BROKER_PORT: 5672
    ECOMMERCE_WORKER_BROKER_TRANSPORT: 'amqp'
    ECOMMERCE_WORKER_CONCURRENCY: 4
    # END CELERY

    # ORDER FULFILLMENT
    # Absolute URL used to construct API calls against the ecommerce service.
    ECOMMERCE_WORKER_ECOMMERCE_API_ROOT: 'http://127.0.0.1:8002/api/v2/'

    # Long-lived access token used by Celery workers to authenticate against the ecommerce service.
    ECOMMERCE_WORKER_WORKER_ACCESS_TOKEN: __vault__:gen_if_missing:secret-residential/{{ environment }}/ecommerce/worker-access-token>data>value

    # Maximum number of retries before giving up on the fulfillment of an order.
    # For reference, 11 retries with exponential backoff yields a maximum waiting
    # time of 2047 seconds (about 30 minutes). Defaulting this to None could yield
    # unwanted behavior: infinite retries.
    ECOMMERCE_WORKER_MAX_FULFILLMENT_RETRIES: 11
    # END ORDER FULFILLMENT

    # Ecommerce Worker settings
    ECOMMERCE_WORKER_JWT_SECRET_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/edxapp-jwt-secret-key>data>value
    ECOMMERCE_WORKER_JWT_ISSUER: 'ecommerce_worker'
    ECOMMERCE_WORKER_SITE_OVERRIDES: !!null
