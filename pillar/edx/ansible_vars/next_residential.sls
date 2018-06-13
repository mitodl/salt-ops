{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set purpose = salt.grains.get('purpose', 'current-residential-live') %}
{% set purpose_prefix = purpose.rsplit('-', 1)[0] %}
{% set purpose_suffix = purpose.replace('-', '_') %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}
{% set MYSQL_HOST = 'mysql.service.consul' %}
{% set MYSQL_PORT = 3306 %}
{% set cloudfront_dist = salt.boto_cloudfront.get_distribution(name=purpose_prefix ~ '-' ~ environment ~ '-cdn') %}

edx:
  ansible_vars:
    EDXAPP_CELERY_BROKER_HOSTNAME: nearest-rabbitmq.query.consul
    EDXAPP_CELERY_BROKER_TRANSPORT: 'amqp'
    EDXAPP_EXTRA_MIDDLEWARE_CLASSES: [] # Worth keeping track of in case we need to take advantage of it
    EDXAPP_MONGO_REPLICA_SET: rs0
    EDXAPP_MYSQL_CSMH_DB_NAME: edxapp_csmh_{{ purpose_suffix }}
    EDXAPP_MYSQL_CSMH_HOST: {{ MYSQL_HOST }}
    EDXAPP_MYSQL_CSMH_PASSWORD: __vault__:cache:mysql-{{ environment }}/creds/edxapp-csmh-{{ purpose }}>data>password
    EDXAPP_MYSQL_CSMH_PORT: {{ MYSQL_PORT }}
    EDXAPP_MYSQL_CSMH_USER: __vault__:cache:mysql-{{ environment }}/creds/edxapp-csmh-{{ purpose }}>data>username
    EDXAPP_PLATFORM_DESCRIPTION: 'MITx Residential Online Course Portal'
    EDXAPP_PRIVATE_REQUIREMENTS:
        # For Harvard courses:
        # Peer instruction XBlock
        - name: ubcpi-xblock==0.6.4
        # Vector Drawing and ActiveTable XBlocks (Davidson)
        - name: git+https://github.com/open-craft/xblock-vectordraw.git@c57df9d98119fd2ca4cb31b9d16c27333cdc65ca#egg=xblock-vectordraw==0.2.1
          extra_args: -e
        - name: git+https://github.com/open-craft/xblock-activetable.git@e933d41bb86a8d50fb878787ca680165a092a6d5#egg=xblock-activetable
          extra_args: -e
       # MITx Residential XBlocks
        - name: edx-sga==0.8.2
        - name: rapid-response-xblock==0.0.2
    EDXAPP_STATIC_URL_BASE: "https://{{ cloudfront_dist.result.distribution.DomainName }}/static/"
    EDXAPP_LMS_ENV_EXTRA:
      GIT_IMPORT_STATIC: true
      ENABLE_CSMH_EXTENDED: True
      ENABLE_READING_FROM_MULTIPLE_HISTORY_TABLES: True
    EDXAPP_CMS_ENV_EXTRA:
      ENABLE_CSMH_EXTENDED: True
      ENABLE_READING_FROM_MULTIPLE_HISTORY_TABLES: True
