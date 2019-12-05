{% set sqs_edxapp_mitxpro_production_queue = 'edxapp-xpro-production-mitxpro-production-autoscaling' %}
{% set sqs_edx_worker_mitxpro_production_queue = 'edx-worker-xpro-production-mitxpro-production-autoscaling' %}
{% set purpose = salt.grains.get('purpose') %}
{% if 'qa' in purpose %}
{% set git_ref = 'master' %}
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
      gitfs_provider: pygit2
      gitfs_remotes:
        - https://github.com/mitodl/salt-ops:
            - root: salt
        - https://github.com/mitodl/salt-extensions:
            - root: extensions
        - https://github.com/mitodl/master-formula
        - https://github.com/mitodl/elasticsearch-formula
        - https://github.com/mitodl/fluentd-formula
        - https://github.com/mitodl/datadog-formula
        - https://github.com/mitodl/consul-formula
        - https://github.com/mitodl/vault-formula
        - https://github.com/mitodl/mongodb-formula
        - https://github.com/mitodl/rabbitmq-formula
        - https://github.com/mitodl/nginx-formula
        - https://github.com/mitodl/letsencrypt-formula
        - https://github.com/mitodl/reddit-formula
        - https://github.com/mitodl/nginx-shibboleth-formula
        - https://github.com/mitodl/uwsgi-formula
        - https://github.com/mitodl/django-formula
        - https://github.com/mitodl/aptly-formula
        - https://github.com/mitodl/pgbouncer-formula
        - https://github.com/mitodl/python-formula
        - https://github.com/mitodl/node-formula
        - https://github.com/mitodl/monit-formula
        - https://github.com/mitodl/elastic-stack-formula
    ext_pillar:
      git_pillar_provider: pygit2
      git_pillar_base: {{ git_ref }}
      ext_pillar:
        - git:
            - {{ git_ref }} https://github.com/mitodl/salt-ops:
                - root: pillar
        - vault: {}
    logging:
      log_granular_levels:
        'py.warnings': 'quiet'
      logstash_udp_handler:
        host: fluentd.service.consul
        port: 9999
        version: 1
    reactors:
      reactor:
        - salt/beacon/*/inotify/*:
            - salt://reactors/edx/inotify_mitx.sls
        - salt/beacon/reddit-*/memusage/*:
            - salt://reactors/reddit/restart_reddit_service_low_memory.sls
            - salt://reactors/opsgenie/post_notification.sls
        - salt/beacon/odl-video-service-*/memusage/*:
            - salt://reactors/apps/restart_uwsgi_service_low_memory.sls
            - salt://reactors/opsgenie/post_notification.sls
        - salt/beacon/*/http_status/*:
            - salt://reactors/opsgenie/post_notification.sls
        - vault/lease/expiring/*:
            - salt://reactors/vault/alert_expiring_leases.sls
        - vault/cache/miss/*:
            - salt://reactors/vault/alert_cache_read_misses.sls
        - salt/state_result/*/restore/*/result:
            - salt://reactors/opsgenie/post_notification.sls
        - salt/state_result/*/backup/*/result:
            - salt://reactors/opsgenie/post_notification.sls
        - backup/*/*/completed:
            - salt://reactors/slack/post_event.sls
        - salt/engine/sqs/mitxpro-production-autoscaling:
            - salt://reactors/mitxpro/edxapp_ec2_autoscale.sls
            - salt://reactors/slack/post_event.sls
        - salt/cloud/edx-*mitxpro-production-xpro-production-*/created:
            - salt://reactors/mitxpro/edxapp_highstate.sls
        - salt/cloud/*/destroying:
            - salt://reactors/vault/cache_cleanup_on_terminate.sls
    engines:
      sqs:
        region: us-east-1
        message_format: json
        id: use-instance-role-credentials
        key: use-instance-role-credentials
      {% if 'production' in purpose %}
      engines:
        - sqs_events:
            queue: {{ sqs_edxapp_mitxpro_production_queue }}
            profile: sqs
            tag: salt/engine/sqs/mitxpro-production-autoscaling
        - sqs_events:
            queue: {{ sqs_edx_worker_mitxpro_production_queue }}
            profile: sqs
            tag: salt/engine/sqs/mitxpro-production-autoscaling
      {% endif %}
    misc:
      worker_threads: 25
      {# this is to avoid timeouts waiting for edx asset compilation during AMI build (TMM 2019-04-01) #}
      gather_job_timeout: 60
    sdb:
      consul:
        driver: consul
        host: consul.service.consul
      osenv:
        driver: env
    vault:
      vault.url: https://active.vault.service.consul:8200
      vault.verify: False
    nodegroups:
      nodegroups:
        logging_cluster:
          - 'G@roles:elasticsearch'
          - 'and'
          - 'G@environment:operations'
        kibana:
          - 'G@roles:kibana'
          - 'and'
          - 'G@environment:operations'
        consul_operations:
          - 'G@roles:consul_server'
          - 'and'
          - 'G@environment:operations'
        consul_mitxpro_prod:
          - 'G@roles:consul_server'
          - 'and'
          - 'G@environment:mitxpro-production'
        consul_mitxpro_qa:
          - 'G@roles:consul_server'
          - 'and'
          - 'G@environment:mitxpro-qa'
        consul_mitx_prod:
          - 'G@roles:consul_server'
          - 'and'
          - 'G@environment:mitx-production'
        consul_mitx_qa:
          - 'G@roles:consul_server'
          - 'and'
          - 'P@environment:mitx-qa'
        consul_apps_prod:
          - 'G@roles:consul_server'
          - 'and'
          - 'G@environment:production-apps'
        consul_apps_rc:
          - 'G@roles:consul_server'
          - 'and'
          - 'P@environment:rc-apps'
        ocw_prod:
          - 'P@roles:ocw'
          - 'and'
          - 'G@ocw-environment:production'
        ocw_qa:
          - 'P@roles:ocw'
          - 'and'
          - 'G@ocw-environment:qa'
        ocw_cms_prod:
          - 'G@roles:ocw-cms'
          - 'and'
          - 'G@ocw-environment:production'
        ocw_cms_qa:
          - 'G@roles:ocw-cms'
          - 'and'
          - 'G@ocw-environment:qa'
        rabbitmq_mitx_prod:
          - 'G@roles:rabbitmq'
          - 'and'
          - 'G@environment:mitx-production'
        rabbitmq_mitx_qa:
          - 'G@roles:rabbitmq'
          - 'and'
          - 'G@environment:mitx-qa'
        rabbitmq_mitxpro_prod:
          - 'G@roles:rabbitmq'
          - 'and'
          - 'G@environment:mitxpro-production'
        rabbitmq_mitxpro_qa:
          - 'G@roles:rabbitmq'
          - 'and'
          - 'G@environment:mitxpro-qa'
        rabbitmq_apps_prod:
          - 'G@roles:rabbitmq'
          - 'and'
          - 'G@environment:production-apps'
        rabbitmq_apps_rc:
          - 'G@roles:rabbitmq'
          - 'and'
          - 'G@environment:rc-apps'
        ovs_rc:
          - 'G@roles:odl-video-service'
          - 'and'
          - 'G@environment:rc-apps'
        ovs_production:
          - 'G@roles:odl-video-service'
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
  proxy_configs:
    apps:
      {% if 'qa' in purpose %}
      - proxy-mitxpro-ci
      - proxy-mitxpro-rc
      - proxy-mit-open-discussions-ci
      - proxy-mit-open-discussions-rc
      {% else %}
      - proxy-mitxpro-production
      - proxy-mit-open-discussions-production
      {% endif %}
