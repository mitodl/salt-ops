{% set ONE_WEEK = 604800 %}
{% set sqs_mitxpro_production_queue = 'edxapp-xpro-production-mitxpro-production-autoscaling' %}

slack_api_token: __vault__::secret-operations/global/slack/slack_api_token>data>value
slack:
  api_key: __vault__::secret-operations/global/slack/slack_api_token>data>value
slack_webhook_url: __vault__::secret-operations/global/slack-odl/slack_webhook_url>data>value

schedule:
  scan_for_expiring_vault_leases:
    maxrunning: 1
    when: Monday 9:00am
    function: vault.scan_leases
    kwargs:
      time_horizon: {{ ONE_WEEK }}
  refresh_master_vault_token:
    maxrunning: 1
    days: 5
    function: vault.renew_token
  refresh_master_configs:
    maxrunning: 1
    days: 21
    function: state.sls
    args:
      - master.config
  backup_edx_rp_data:
    maxrunning: 1
    when: 1:00am
    function: saltutil.runner
    args:
      - state.orchestrate
    kwargs:
      mods: orchestrate.edx.backup
  restore_edx_qa_data:
    maxrunning: 1
    when: Monday 1:00pm
    function: saltutil.runner
    args:
      - state.orchestrate
    kwargs:
      mods: orchestrate.edx.restore
  backup_operations_data:
    maxrunning: 1
    when: 1:00am
    function: saltutil.runner
    args:
      - state.orchestrate
    kwargs:
      mods: orchestrate.operations.backups
  delete_edx_logs_older_than_30_days:
    maxrunning: 1
    when: Sunday 5:00am
    function: state.sls
    args:
      - edx.maintenance_tasks

salt_master:
  libgit:
    release: '0.27.3'
    hash: 50a57bd91f57aa310fb7d5e2a340b3779dc17e67b4e7e66111feac5c2432f1a5
  overrides:
    pkgs:
      - build-essential
      - curl
      - emacs
      - git
      - libffi-dev
      - libssh2-1-dev
      - libssl-dev
      - mosh
      - python-dev
      - python-pip
      - reclass
      - salt-api
      - salt-cloud
      - salt-doc
      - tmux
      - vim
    pip_deps:
      - PyOpenssl
      - apache-libcloud
      - boto3
      - boto>=2.35.0
      - croniter
      - elasticsearch
      - python-consul
      - python-dateutil
      - pyyaml
      - requests
  ssl:
    cert_path: /etc/salt/ssl/certs/salt.odl.mit.com.crt
    key_path: /etc/salt/ssl/certs/salt.odl.mit.com.key
    cert_params:
      emailAddress: mitx-devops@mit.edu
      bits: 4096
      CN: salt.odl.mit.edu
      ST: MA
      L: Boston
      O: MIT
      OU: Office of Digital Learning
  extra_configs:
    extfs:
      fileserver_backend:
        - git
        - roots
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
      ext_pillar:
        - git:
            - master https://github.com/mitodl/salt-ops:
                - root: pillar
        - vault: {}
    logging:
      log_granular_levels:
        'py.warnings': 'quiet'
      logstash_udp_handler:
        host: fluentd.service.operations.consul
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
      engines:
        - sqs_events:
            queue: {{ sqs_mitxpro_production_queue }}
            profile: sqs
            tag: salt/engine/sqs/mitxpro-production-autoscaling
    misc:
      worker_threads: 25
      {# this is to avoid timeouts waiting for edx asset compilation during AMI build (TMM 2019-04-01) #}
      gather_job_timeout: 30
      master_job_cache: pgjsonb
      event_return: pgjsonb
      returner.pgjsonb.host: postgres-saltmaster.service.consul
      returner.pgjsonb.port: 5432
      returner.pgjsonb.user: __vault__:cache:postgres-operations-saltmaster/creds/saltmaster>data>username
      returner.pgjsonb.pass: __vault__:cache:postgres-operations-saltmaster/creds/saltmaster>data>password
      returner.pgjsonb.db: saltmaster
    sdb:
      consul:
        driver: consul
        host: consul.service.operations.consul
    vault:
      vault.url: https://active.vault.service.consul:8200
      vault.verify: False
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
        host: consul.service.operations.consul
  aws:
    providers:
      - name: mitx
        id: use-instance-role-credentials
        key: use-instance-role-credentials
        keyname: salt-master-prod
        private_key_path: /etc/salt/keys/aws/salt-master-prod.pem
        extra_params:
          script_args: -U -F -A salt.private.odl.mit.edu
          sync_after_install: all
          delete_ssh_keys: True
      - name: mitx-stage
        id: __vault__::secret-operations/global/mitx-staging-iam-credentials>data>id
        key: __vault__::secret-operations/global/mitx-staging-iam-credentials>data>secret_key
        keyname: salt-master-stage
        private_key_path: /etc/salt/keys/aws/salt-master-stage.pem
        region: us-west-2
        extra_params:
          script_args: -U -P
          sync_after_install: all
          delete_ssh_keys: True
  proxy_configs:
    apps:
      - proxy-mitxpro-ci
      - proxy-mitxpro-rc
      - proxy-mitxpro-production
      - proxy-mit-open-discussions-ci
      - proxy-mit-open-discussions-rc
      - proxy-mit-open-discussions-production
