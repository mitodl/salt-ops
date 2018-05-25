{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set purpose = salt.grains.get('purpose', 'current-residential-live') %}
{% set purpose_suffix = purpose.replace('-', '_') %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}
{% set MYSQL_HOST = 'mysql.service.consul' %}
{% set MYSQL_PORT = 3306 %}

edx:
  config:
    repo: https://github.com/mitodl/configuration.git
    branch: master
  playbooks:
    - 'edx-east/edxapp.yml'
    - 'edx-east/worker.yml'
  ansible_vars:
    EDXAPP_MONGO_REPLICA_SET: rs0
    EDXAPP_CELERY_BROKER_HOSTNAME: nearest-rabbitmq.query.consul
    EDXAPP_CELERY_BROKER_TRANSPORT: 'amqp'
    EDXAPP_PLATFORM_DESCRIPTION: 'MITx Residential Sandbox'
    EDXAPP_PLATFORM_NAME: 'MITx Residential Sandbox'
    EDXAPP_AWS_STORAGE_BUCKET_NAME: ""
    EDXAPP_DEFAULT_FILE_STORAGE: "django.core.files.storage.FileSystemStorage"
    EDXAPP_MYSQL_CSMH_DB_NAME: edxapp_csmh_{{ purpose_suffix }}
    EDXAPP_MYSQL_CSMH_HOST: {{ MYSQL_HOST }}
    EDXAPP_MYSQL_CSMH_PASSWORD: __vault__:cache:mysql-{{ environment }}/creds/edxapp-csmh-{{ purpose }}>data>password
    EDXAPP_MYSQL_CSMH_PORT: {{ MYSQL_PORT }}
    EDXAPP_MYSQL_CSMH_USER: __vault__:cache:mysql-{{ environment }}/creds/edxapp-csmh-{{ purpose }}>data>username
    EDXAPP_MEMCACHE:
      - 'localhost:11211'
    EDXAPP_LMS_ENV_EXTRA:
      FEATURES:
        ENABLE_COMBINED_LOGIN_REGISTRATION: false
        ENABLE_THIRD_PARTY_AUTH: false
        AUTH_USE_CAS: false
    EDXAPP_PRIVATE_REQUIREMENTS:
        # MITx Residential XBlocks
        - name: git+https://github.com/mitodl/rapid-response-xblock@4251bb15124bdf0b681b431fa1cd67fd094387c4#egg=rapid-response-xblock
          extra_args: -e
