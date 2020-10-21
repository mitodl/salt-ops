{% set env_settings = salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml", dest=None)|load_yaml %}
{% set purpose = salt.grains.get('purpose', 'current-residential-live') %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}
{% set env_data = env_settings.environments[environment] %}
{% set purpose_suffix = purpose.replace('-', '_') %}
{% set purpose_data = env_data.purposes[purpose] %}
{% set business_unit = purpose_data.business_unit %}
{% set MYSQL_HOST = 'mysql.service.consul' %}
{% set MYSQL_PORT = 3306 %}
{% set MONGODB_HOST = 'mongodb-master.service.consul' %}
{% set MONGODB_PORT = 27017 %}

edx:
  config:
    repo: https://github.com/mitodl/configuration.git
    branch: master
  playbooks:
    - 'edx-east/edxapp.yml'
    - 'edx-east/worker.yml'
    - 'edx-east/forum.yml'
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
    ################################################################################
    #################### Forum Settings ############################################
    ################################################################################
    FORUM_API_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/global/forum-api-key>data>value
    FORUM_ELASTICSEARCH_HOST: "nearest-elasticsearch.query.consul"
    FORUM_MONGO_USER: __vault__:cache:mongodb-{{ environment }}/creds/forum-{{ purpose }}>data>username
    FORUM_MONGO_PASSWORD: __vault__:cache:mongodb-{{ environment }}/creds/forum-{{ purpose }}>data>password
    FORUM_MONGO_HOSTS:
      - {{ MONGODB_HOST }}
    FORUM_MONGO_PORT: {{ MONGODB_PORT }}
    {# multivariate #}
    FORUM_MONGO_DATABASE: forum_{{ purpose_suffix }}
    FORUM_RACK_ENV: "production"
    FORUM_SINATRA_ENV: "production"
    FORUM_USE_TCP: True
    forum_source_repo: {{ purpose_data.versions.forum_source_repo }}
    forum_version: {{ purpose_data.versions.forum }}
    ########## END FORUM ########################################
    EDXAPP_LMS_ENV_EXTRA:
      FEATURES:
        ENABLE_COMBINED_LOGIN_REGISTRATION: false
        ENABLE_GRADE_DOWNLOADS: true
        ENABLE_THIRD_PARTY_AUTH: false
        AUTH_USE_CAS: false
    EDXAPP_PRIVATE_REQUIREMENTS:
        # MITx Residential XBlocks
        - name: git+https://github.com/mitodl/rapid-response-xblock@4251bb15124bdf0b681b431fa1cd67fd094387c4#egg=rapid-response-xblock
          extra_args: -e
