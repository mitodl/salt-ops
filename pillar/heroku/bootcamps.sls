{% set minion_id = salt.grains.get('id', '') %}
{% set environment = minion_id.split('-')[-1] %}
{% set rds_endpoint = salt.boto_rds.get_endpoint('bootcamps-rds-postgresql') %}

{% set env_dict = {
    'ci': {
      'app_name': 'xpro-ci',
      'env_name': 'ci',
      'BOOTCAMP_ADMISSION_BASE_URL': 'http://admissions-test.herokuapp.com',
      'BOOTCAMP_ECOMMERCE_BASE_URL': 'https://bootcamp-ecommerce-ci.herokuapp.com',
      'BOOTCAMP_LOG_LEVEL': 'INFO',
      'BOOTCAMP_SUPPORT_EMAIL': 'bootcamp-support@mit.edu',
      'CYBERSOURCE_REFERENCE_PREFIX': 'ci',
      'EDXORG_BASE_URL': 'https://micromasters.d.mitx.mit.edu',
      'GA_TRACKING_ID': 'UA-5145472-19',
      'GTM_TRACKING_ID': 'GTM-NZT8SRC',
      'vault_env_path': 'rc-apps'
      },
    'rc': {
      'app_name': 'xpro-rc',
      'env_name': 'rc',
      'BOOTCAMP_ADMISSION_BASE_URL': 'http://admissions-test.herokuapp.com',
      'BOOTCAMP_ECOMMERCE_BASE_URL': 'http://bootcamp-rc.odl.mit.edu/',
      'BOOTCAMP_LOG_LEVEL': 'INFO',
      'BOOTCAMP_SUPPORT_EMAIL': 'bootcamp-support@mit.edu',
      'CYBERSOURCE_REFERENCE_PREFIX': 'rc',
      'EDXORG_BASE_URL': 'https://courses.stage.edx.org',
      'GA_TRACKING_ID': 'UA-5145472-19',
      'GTM_TRACKING_ID': 'GTM-NZT8SRC',
      'vault_env_path': 'rc-apps'
      },
    'production': {
      'app_name': 'xpro-production',
      'env_name': 'production',
      'BOOTCAMP_ADMISSION_BASE_URL': 'http://admissions.herokuapp.com',
      'BOOTCAMP_ECOMMERCE_BASE_URL': 'https://bootcamp.odl.mit.edu/',
      'BOOTCAMP_LOG_LEVEL': 'INFO',
      'BOOTCAMP_SUPPORT_EMAIL': 'bootcamp@mit.edu',
      'CYBERSOURCE_REFERENCE_PREFIX': 'prod',
      'EDXORG_BASE_URL': 'https://courses.edx.org',
      'GA_TRACKING_ID': 'UA-5145472-18',
      'GTM_TRACKING_ID': 'GTM-NZT8SRC',
      'vault_env_path': 'production-apps'
      }
} %}
{% set env_data = env_dict[environment] %}
{% set business_unit = 'bootcamps' %}
{% set cybersource_creds = salt.vault.read('secret-' ~ business_unit ~ '/' ~ env_data.vault_env_path ~ '/cybersource').data %}
{% set fluidreview = salt.vault.read('secret-' ~ business_unit ~ '/' ~ env_data.vault_env_path ~ '/fluidreview').data %}
{% set smapply = salt.vault.read('secret-' ~ business_unit ~ '/' ~ env_data.vault_env_path ~ '/smapply').data %}

proxy:
  proxytype: heroku

heroku:
  app_name: {{ env_data.app_name }}
  api_key: __vault__::secret-operations/global/heroku/api_key>data>value
  config_vars:
    ALLOWED_HOSTS: '[*]'
    BOOTCAMP_ADMIN_EMAIL: cuddle-bunnies@mit.edu
    BOOTCAMP_ADMISSION_BASE_URL: {{ env_data.BOOTCAMP_ADMISSION_BASE_URL }}
    BOOTCAMP_ADMISSION_KEY: __vault__::secret-{{ business_unit }}/{{ env_data.vault_env_path }}/>admissions>admission_key>data>value
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
    CYBERSOURCE_ACCESS_KEY: {{ cybersource_creds.access_key }}
    CYBERSOURCE_PROFILE_ID: {{ cybersource_creds.profile_id }}
    CYBERSOURCE_REFERENCE_PREFIX: {{ env_data.CYBERSOURCE_REFERENCE_PREFIX }}
    CYBERSOURCE_SECURE_ACCEPTANCE_URL: {{ env_data.CYBERSOURCE_SECURE_ACCEPTANCE_URL}}
    CYBERSOURCE_SECURITY_KEY: {{ cybersource_creds.security_key }}
    {% if env_data.env_name == 'production' %}
    {% set pg_creds = salt.vault.cached_read('postgresql-bootcamps/creds/app', cache_prefix='heroku-bootcamp') %}
    BOOTCAMP_ECOMMERCE_EMAIL: __vault__::secret-{{ business_unit }}/production-apps/>cybersource>data>email
    CYBERSOURCE_TRANSACTION_KEY: 'none'
    DATABASE_URL: postgres://{{ pg_creds.data.username }}:{{ pg_creds.data.password }}@{{ rds_endpoint }}/bootcamp_ecommerce
    ENABLE_STUNNEL_AMAZON_RDS_FIX: true
    HIREFIRE_TOKEN: __vault__::secret-{{ business_unit }}/production-apps/hirefire_token>data>value
    {% endif %}
    EDXORG_BASE_URL: {{ env_data.EDXORG_BASE_URL }}
    EDXORG_CLIENT_ID: __vault__::secret-{{ business_unit }}/{{ env_data.vault_env_path }}/>edx>data>client_id
    EDXORG_CLIENT_SECRET: __vault__::secret-{{ business_unit }}/{{ env_data.vault_env_path }}/>edx>data>client_secret
    FLUIDREVIEW_ACCESS_TOKEN: {{ fluidreview.access_token }}
    FLUIDREVIEW_AMOUNTPAID_ID: {{ fluidreview.amountpaid_id }}
    FLUIDREVIEW_BASE_URL:  {{ fluidreview.base_url }}
    FLUIDREVIEW_CLIENT_ID:  {{ fluidreview.client_id }}
    FLUIDREVIEW_CLIENT_SECRET:  {{ fluidreview.client_secret }}
    FLUIDREVIEW_REFRESH_TOKEN:  {{ fluidreview.refresh_token }}
    FLUIDREVIEW_WEBHOOK_AUTH_TOKEN:  {{ fluidreview.webhook_auth_token }}
    GA_TRACKING_ID: {{ env_data.GA_TRACKING_ID }}
    GTM_TRACKING_ID: {{ env_data.GTM_TRACKING_ID }}
    HUBSPOT_API_KEY: __vault__::secret-{{ business_unit }}/{{ env_data.vault_env_path }}/>hubspot>data>api_key
    HUBSPOT_ID_PREFIX: __vault__::secret-{{ business_unit }}/{{ env_data.vault_env_path }}/>hubspot>data>id_prefix
    MAILGUN_KEY: __vault__::secret-operations/global/mailgun-api-key>data>value
    NEW_RELIC_APP_NAME: Bootcamp {{ env_data.env_name }}
    NODE_MODULES_CACHE: False
    PGBOUNCER_DEFAULT_POOL_SIZE: 50
    PGBOUNCER_MIN_POOL_SIZE: 5
    SECRET_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/django-secret-key>data>value
    SENTRY_DSN: __vault__::secret-operations/global/{{ business_unit} }/sentry-dsn>data>value
    SMAPPLY_ACCESS_TOKEN: {{ smapply.access_token }}
    SMAPPLY_AMOUNTPAID_ID: {{ smapply.amountpaid_id }}
    SMAPPLY_AMOUNT_TO_PAY_ID: {{ smapply.amount_to_pay_id }}
    SMAPPLY_AWARD_COST_ID: {{ smapply.award_cost_id }}
    SMAPPLY_BASE_URL: {{ smapply.base_url }}
    SMAPPLY_CLIENT_ID: {{ smapply.client_id }}
    SMAPPLY_CLIENT_SECRET: {{ smapply.client_secret }}
    SMAPPLY_REFRESH_TOKEN: {{ smapply.refresh_token }}
    SMAPPLY_WEBHOOK_AUTH_TOKEN: {{ smapply.webhook_auth_token }}
    STATUS_TOKEN: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/django-status-token>data>value
