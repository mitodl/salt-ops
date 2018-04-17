edx:
  config:
    repo: https://github.com/mitodl/configuration.git
    branch: open-release/ginkgo.master
  playbooks:
    - 'edx-east/edxapp.yml'
  ansible_vars:
    EDXAPP_MONGO_REPLICA_SET: rs0
    EDXAPP_CELERY_BROKER_HOSTNAME: nearest-rabbitmq.query.consul
    EDXAPP_CELERY_BROKER_TRANSPORT: 'amqp'
    EDXAPP_PLATFORM_DESCRIPTION: 'MITx Residential Sandbox'
    EDXAPP_PLATFORM_NAME: 'MITx Residential Sandbox'
    EDXAPP_LMS_ENV_EXTRA:
      FEATURES:
        ENABLE_COMBINED_LOGIN_REGISTRATION: false
        ENABLE_THIRD_PARTY_AUTH: false
        AUTH_USE_CAS: false
