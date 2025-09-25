{% set sqs_edxapp_mitxpro_production_queue = 'edxapp-xpro-production-mitxpro-production-autoscaling' %}
{% set sqs_edx_worker_mitxpro_production_queue = 'edx-worker-xpro-production-mitxpro-production-autoscaling' %}
{% set purpose = salt.grains.get('purpose') %}
{% if 'qa' in purpose %}
{% set git_ref = 'main' %}
{% else %}
{% set git_ref = 'production' %}
{% endif %}

slack_api_token: __vault__::secret-operations/global/slack/slack_api_token>data>value
slack:
  api_key: __vault__::secret-operations/global/slack/slack_api_token>data>value
slack_webhook_url: __vault__::secret-operations/global/slack-odl/slack_webhook_url>data>value

salt_master:
  extra_configs:
    extfs:
      fileserver_backend:
        - gitfs
        - roots
      gitfs_base: {{ git_ref }}
      gitfs_provider: gitpython
      gitfs_remotes:
        - https://github.com/mitodl/salt-ops:
            - root: salt
        - https://github.com/mitodl/salt-extensions:
            - root: extensions
        - https://github.com/mitodl/master-formula
        - https://github.com/mitodl/vault-formula
        - https://github.com/mitodl/rabbitmq-formula
        - https://github.com/mitodl/nginx-formula
        - https://github.com/mitodl/reddit-formula
        - https://github.com/mitodl/uwsgi-formula
        - https://github.com/mitodl/pgbouncer-formula
        - https://github.com/mitodl/python-formula
    ext_pillar:
      git_pillar_provider: gitpython
      git_pillar_base: {{ git_ref }}
      ext_pillar:
        - git:
            - {{ git_ref }} https://github.com/mitodl/salt-ops:
                - root: pillar
        - vault: {}
    logging:
      log_granular_levels:
        'py.warnings': 'quiet'
    reactors:
      reactor:
        - salt/beacon/reddit-*/memusage/*:
            - salt://reactors/reddit/restart_reddit_service_low_memory.sls
    misc:
      worker_threads: 25
      keep_jobs: 24
      {# this is to avoid timeouts waiting for edx asset compilation during AMI build (TMM 2019-04-01) #}
      gather_job_timeout: 60
    sdb:
      consul:
        driver: consul
        host: consul.service.consul
      osenv:
        driver: env
      yaml:
        driver: yaml
        files:
          - salt://sdb/keys.yaml
    vault:
      vault.url: https://active.vault.service.consul:8200
      vault.verify: False
    nodegroups:
      nodegroups:
        rabbitmq_apps_prod:
          - 'G@roles:rabbitmq'
          - 'and'
          - 'G@environment:production-apps'
  minion_configs:
    vault:
      vault.url: https://active.vault.service.consul:8200
      vault.verify: False
    extra_settings:
      grains:
        roles:
          - master
    sdb:
      consul:
        driver: consul
        host: consul.service.consul
      yaml:
        driver: yaml
        files:
          - salt://sdb/keys.yaml
