{% set ONE_WEEK = 604800 %}
{% set slack_api_token = salt.vault.read('secret-operations/global/slack/slack_api_token').data.value %}

slack_api_token: {{ slack_api_token }}
slack:
  api_key: {{ slack_api_token }}
slack_webhook_url: {{ salt.vault.read('secret-operations/global/slack/slack_webhook_url').data.value }}

schedule:
  scan_for_expiring_vault_leases:
    maxrunning: 1
    when: Monday 9:00am
    function: vault.scan_leases
    kwargs:
      time_horizon: {{ ONE_WEEK }}
  refresh_master_vault_token:
    maxrunning: 1
    days: 29
    function: state.sls
    args:
      - vault.refresh_master_token
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
        - https://github.com/mitodl/edx-sandbox-formula
        - https://github.com/mitodl/nginx-formula
        - https://github.com/mitodl/letsencrypt-formula
        - https://github.com/hubblestack/hubble-salt
        - https://github.com/mitodl/reddit-formula
        - https://github.com/mitodl/nginx-shibboleth-formula
        - https://github.com/mitodl/uwsgi-formula
        - https://github.com/mitodl/django-formula
        - https://github.com/mitodl/aptly-formula
        - https://github.com/mitodl/pgbouncer-formula
    ext_pillar:
      git_pillar_provider: pygit2
      ext_pillar:
        - git:
            - master git@github.mit.edu:mitx-devops/salt-pillar:
                - privkey: /etc/salt/keys/ssh/github_mit
                - pubkey: /etc/salt/keys/ssh/github_mit.pub
    logging:
      logstash_udp_handler:
        host: fluentd.service.operations.consul
        port: 9999
        version: 1
    reactors:
      reactor:
        - salt/beacon/edx-*/diskusage/*:
            - salt://reactors/edx/draft_disk_cleanup.sls
        - salt/beacon/*/inotify/*:
            - salt://reactors/edx/inotify_mitx.sls
        - vault/lease/expiring/*:
            - salt://reactors/vault/alert_expiring_leases.sls
    returner:
      event_return: elasticsearch
      master_job_cache: elasticsearch
      elasticsearch:
        hosts:
          - http://elasticsearch.service.operations.consul:9200
    sdb:
      consul:
        driver: consul
        host: consul.service.operations.consul
    vault:
      vault.url: https://vault.service.consul:8200
      vault.verify: False
  minion_configs:
    vault:
      vault.url: https://vault.service.consul:8200
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
          script_args: -U -Z -F
          sync_after_install: all
          delete_ssh_keys: True
      {% set aws_staging_iam_credentials = salt.vault.read('secret-operations/global/mitx-staging-iam-credentials') %}
      - name: mitx-stage
        id: {{ aws_staging_iam_credentials.data.id }}
        key: {{ aws_staging_iam_credentials.data.secret_key }}
        keyname: salt-master-stage
        private_key_path: /etc/salt/keys/aws/salt-master-stage.pem
        region: us-west-2
        extra_params:
          script_args: -U -Z -P
          sync_after_install: all
          delete_ssh_keys: True
  slack:
    api_key: {{ slack_api_token }}
