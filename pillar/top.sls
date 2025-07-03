base:
  '* and not proxy-*':
    - match: compound
    - common
    - environment_settings
    - vector
  'roles:master':
    - match: grain
    - master
    - master.config
    - vault.roles.apps
    - vault.roles.aws
    - vault.roles.bootcamps
    - vault.roles.micromasters
  master-operations-production:
    - master.production_schedule
  master-operations-qa:
    - master.qa_schedule
  'roles:cassandra':
    - match: grain
    - cassandra
    - consul.cassandra
  'roles:reddit':
    - match: grain
    - nginx
    - nginx.reddit
    - vector.reddit
    - reddit
  'P@environment:(operations|operations-qa|rc-apps|production-apps)':
    - match: compound
    - consul
  'P@environment:.*apps.*':
    - match: compound
    - consul.apps
  'environment:operations':
    - match: grain
    - consul.operations
  'P@environment:(rc|production)-apps':
    - match: compound
    - rabbitmq.apps
    - consul.apps
  'roles:rabbitmq':
    - match: grain
    - rabbitmq
    - consul.rabbitmq
    - vector.rabbitmq
