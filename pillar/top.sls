base:
  '*':
    - common
    - environment_settings
    - fluentd
  'roles:auth_server':
    - match: grain
    - fluentd.cas
  'roles:elasticsearch':
    - match: grain
    - fluentd.elasticsearch
    - consul.elasticsearch
    - datadog.elasticsearch-integration
  'roles:kibana':
    - match: grain
    - kibana
  'roles:master':
    - match: grain
    - salt_master
    - micromasters
  'roles:fluentd':
    - match: grain
    - fluentd
  'roles:fluentd-server':
    - match: grain
    - fluentd.server
    - datadog.fluentd-integration
    - consul.fluentd
  'roles:consul_server':
    - match: grain
    - consul.server
    - fluentd.consul
    - datadog.consul-integration
  'roles:mongodb':
    - match: grain
    - mongodb
    - fluentd.mongodb
    - consul.mongodb
    - datadog.mongodb-integration
  'G@roles:rabbitmq and P@environment:(mitx-production|production-apps)':
    - match: compound
    - datadog.rabbitmq-integration
  'G@roles:rabbitmq and P@environment:mitx.*':
    - match: compound
    - rabbitmq.mitx
  'roles:rabbitmq':
    - match: grain
    - rabbitmq
    - fluentd.rabbitmq
    - consul.rabbitmq
  'roles:scylladb':
    - match: grain
    - scylladb
    - consul.scylladb
  'roles:cassandra':
    - match: grain
    - cassandra
    - consul.cassandra
    - datadog.cassandra-integration
  'roles:reddit':
    - match: grain
    - nginx
    - nginx.reddit
    - reddit
    - fluentd.reddit
  'P@environment:(mitx-qa|mitx-production|operations|rc-apps|production-apps)':
    - match: compound
    - datadog
    - consul
  'P@environment:mitx-(qa|production)':
    - match: compound
    - consul.mitx
  'environment:operations':
    - match: grain
    - consul.operations
  'P@environment:(rc|production)-apps':
    - match: compound
    - rabbitmq.apps
    - consul.apps
  'G@roles:consul_server and G@environment:operations':
    - match: compound
    - consul.bootcamps
    - vault
  'G@roles:consul_server and G@environment:mitx-production':
    - match: compound
    - datadog.mysql-integration
  'P@roles:(vault_server|master)':
    - match: compound
    - vault
    - vault.roles.apps
    - vault.roles.aws
    - vault.roles.bootcamps
    - vault.roles.micromasters
    - vault.roles.mitx
    - vault.roles.operations
  'G@roles:elasticsearch and G@environment:mitx-qa':
    - match: compound
    - elasticsearch.mitx-qa
  'G@roles:elasticsearch and P@environment:mitx-production':
    - match: compound
    - elasticsearch.mitx-production
  'G@roles:elasticsearch and G@environment:micromasters':
    - match: compound
    - elasticsearch.micromasters
    - datadog.nginx-integration
  'G@roles:elasticsearch and G@environment:operations':
    - match: compound
    - elasticsearch.logging
  'P@roles:(edx|edx-worker)':
    - match: compound
    - edx
    - edx.ansible_vars
    - edx.scheduled_jobs
    - fluentd.mitx
    - datadog.nginx-integration
    - datadog.supervisord-integration
  'P@roles:(edx|edx-worker) and G@environment:mitx-qa':
    - match: compound
    - edx.mitx-qa
    - edx.inotify_mitx
  'G@roles:edx and G@environment:mitx-production':
    - match: compound
    - edx.mitx-production
    - edx.inotify_mitx
  'P@purpose:.*-draft and P@environment:mitx-(qa|production)':
    - match: compound
    - consul.mitx-draft
  'P@purpose:.*-live and P@environment:mitx-(qa|production)':
    - match: compound
    - edx.mitx_etl
    - consul.mitx-live
  'P@purpose:(current-|next-)?residential.*':
    - match: compound
    - edx.next_residential
  'roles:xqwatcher':
    - match: grain
    - edx.xqwatcher
    - fluentd.xqwatcher
  'G@roles:backups and P@environment:mitx-(qa|production)':
    - match: compound
    - backups.mitx
  'G@roles:restores and P@environment:mitx-(qa|production)':
    - match: compound
    - backups.mitx
    - backups.restore
  'G@roles:backups and P@environment:operations':
    - match: compound
    - backups.operations
  'G@roles:devstack and P@environment:dev':
    - match: compound
    - devstack
    - consul_devstack
    - mysql_devstack
    - rabbitmq_devstack
    - elasticsearch_devstack
    - mongodb_devstack
