{% set minion_id = salt.grains.get('id', '') %}
{% set environment = minion_id.split('-')[-1] %}

{% set env_dict = {
    'ci': {
      'app_name': 'ocw-studio-ci',
      'env_name': 'ci',
      'MAILGUN_SENDER_DOMAIN': 'ocw-ci.mail.odl.mit.edu',
      'SITE_NAME': 'MIT OCW Studio CI',
      'vault_env_path': 'rc-apps'
      },
    'rc': {
      'app_name': 'ocw-studio-rc',
      'env_name': 'rc',
      'MAILGUN_SENDER_DOMAIN': 'ocw-rc.mail.odl.mit.edu',
      'SITE_NAME': 'MIT OCW Studio RC',
      'vault_env_path': 'rc-apps'
      },
    'production': {
      'app_name': 'ocw-studio',
      'env_name': 'production',
      'MAILGUN_SENDER_DOMAIN': 'ocw.mail.odl.mit.edu',
      'SITE_NAME': 'MIT OCW Studio',
      'vault_env_path': 'production-apps'
      }
} %}
{% set env_data = env_dict[environment] %}
{% set business_unit = 'ocw' %}

proxy:
  proxytype: heroku

heroku:
  app_name: {{ env_data.app_name }}
  api_key: __vault__::secret-operations/global/heroku/api_key>data>value
  config_vars:
    ALLOWED_HOSTS: '["*"]'
    AWS_ACCESS_KEY_ID:  __vault__:cache:aws-mitx/creds/read-write-delete-ol-ocw-studio-app-{{ env_data.env_name }}>data>access_key
    AWS_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/read-write-delete-ol-ocw-studio-app-{{ env_data.env_name }}>data>secret_key
    AWS_STORAGE_BUCKET_NAME: 'ol-ocw-studio-app-{{ env_data.env_name }}'
    MAILGUN_FROM_EMAIL: 'MIT OCW <no-reply@{{ env_data.MAILGUN_SENDER_DOMAIN }}'
    MAILGUN_KEY: __vault__::secret-operations/global/mailgun-api-key>data>value
    MAILGUN_SENDER_DOMAIN: {{ env_data.MAILGUN_SENDER_DOMAIN }}
    MAILGUN_URL: https://api.mailgun.net/v3/{{ env_data.MAILGUN_SENDER_DOMAIN }}
    OCW_STUDIO_ADMIN_EMAIL: cuddle-bunnies@mit.edu
    SECRET_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/django-secret-key>data>value
