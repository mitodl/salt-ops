{% from "shared/edx/mitx.jinja" import edx with context %}

edx:
  config:
    repo: https://github.com/edx/configuration.git
    branch: master
  ansible_vars:
    EDXAPP_MONGO_REPLICA_SET: rs0
    EDXAPP_FERNET_KEYS: {{ salt.vault.read('secret-residential/{env}/edxapp-fernet-keys').data.value }}
    EDXAPP_CELERY_BROKER_HOSTNAME: rabbitmq-nearest.query.consul
    EDXAPP_CELERY_BROKER_TRANSPORT: 'amqp'
    EDXAPP_PLATFORM_DESCRIPTION: 'MITx Residential Online Course Portal'
    EDXAPP_EXTRA_MIDDLEWARE_CLASSES: [] # Worth keeping track of in case we need to take advantage of it
