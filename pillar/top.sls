base:
  '* and not proxy-*':
    - match: compound
    - common
    - environment_settings
  '* and not proxy-* and not restore-* and not G@roles:devstack and not G@context:packer':
    - match: compound
    - fluentd
  'P@environment:(rc.*|.*-qa)':
    - match: compound
    - elastic_stack.version_qa
  'not P@environment:(rc.*|.*-qa)':
    - match: compound
    - elastic_stack.version_production
  'roles:auth_server':
    - match: grain
    - fluentd.cas
  'G@roles:elasticsearch and not P@environment:operations*':
    - match: compound
    - elasticsearch
    - fluentd.elasticsearch
    - consul.elasticsearch
    - datadog.elasticsearch-integration
  'roles:kibana':
    - match: grain
    - mitca
    - elastic_stack.kibana
    - elastic_stack.beats
    - nginx
    - nginx.kibana
    - elastalert
    - logrotate.kibana
  'G@roles:kibana and G@environment:operations':
    - match: compound
    - datadog.elastalert-process-integration
  'roles:master':
    - match: grain
    - master
    - master.config
    - elastic_stack.beats
    - master.api
    - caddy
    - caddy.master
  master-operations-production:
    - master.production_schedule
    # - master.extra_config
  master-operations-qa:
    - master.qa_schedule
  'roles:dagster':
    - match: grain
    - dagster
    - dagster.xpro_edx
    - dagster.residential_edx
    - dagster.enrollments
    - consul
    - caddy
    - caddy.dagster
  'roles:fluentd':
    - match: grain
    - fluentd
  'roles:zookeeper':
    - match: grain
    - zookeeper
    - consul.zookeeper
  'roles:bookkeeper':
    - match: grain
    - bookkeeper
    - consul.bookkeeper
  'roles:pulsar':
    - match: grain
    - pulsar
    - consul.pulsar
  'G@roles:fluentd-server and G@environment:operations-qa':
    - match: compound
    - consul.fluentd
    - fluentd.server_operations_qa
  'G@roles:fluentd-server and G@environment:operations':
    - match: compound
    - consul.fluentd
    - fluentd.server
    - datadog.fluentd-integration
  'roles:consul_server':
    - match: grain
    - consul
    - consul.server
    - fluentd.consul
    - datadog.consul-integration
    - caddy
    - caddy.consul
    - caddy.odl_wildcard_tls
  'roles:mongodb':
    - match: grain
    - mongodb
    - fluentd.mongodb
    - consul.mongodb
  mongodb*production*:
    - datadog.mongodb-integration
  dremio*:
    - dremio
    - nginx
    - nginx.dremio
    - consul
    - consul.dremio
  starcellbio*:
    - apps.starcellbio
    - nginx
    - nginx.starcellbio
    - consul
  odl-video-service*:
    - apps.odlvideo
    - nginx
    - nginx.odlvideo
    - consul
    - shibboleth
    - shibboleth.odlvideo
    - fluentd.odlvideo
    - logrotate.odlvideo
    - elastic_stack.beats
  proxy-bootcamps-*:
    - heroku.bootcamps
  proxy-mitxpro-*:
    - heroku.xpro
  proxy-mit-open-discussions-*:
    - heroku.discussions
  proxy-ocw-studio-*:
    - heroku.ocw-studio
  'roles:mitx-cas':
    - match: grain
    - apps.mitx_cas
    - nginx
    - nginx.mitx_cas
    - consul
    - shibboleth
    - shibboleth.mitx_cas
    - fluentd.cas
  'G@roles:rabbitmq and P@environment:mitx.*':
    - match: compound
    - rabbitmq.mitx
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
  'G@environment:operations and G@roles:redash':
    - match: compound
    - nginx
    - nginx.redash
    - consul
    - shibboleth
    - shibboleth.redash
    - apps.redash
    - apps.redash_data_sources
    - data.email_mapping_etl
  'P@environment:(mitx-qa|mitx-production|mitxpro-qa|mitxpro-production|operations|rc-apps|production-apps|micromasters)':
    - match: compound
    - datadog
    - consul
    - elastic_stack.beats
  'P@environment:mitx(pro)?-(qa|production)':
    - match: compound
    - consul.mitx
  'P@environment:(operations|data)(-qa|-production)?':
    - match: compound
    - consul.operations
    - vault
  'P@environment:(rc|production)-apps':
    - match: compound
    - rabbitmq.apps
    - consul.apps
  'G@roles:edx-analytics and P@environment:mitx(pro)?-production':
    - match: compound
    - data.mitx_etl
  'G@roles:consul_server and P@environment:operations(-qa)?':
    - match: compound
    - consul.bootcamps
    - vault
  'G@roles:consul_server and P@environment:mitx(pro)?-production':
    - match: compound
    - datadog.mysql-integration
    - datadog.http-check-integration
  'P@roles:(vault_server|master)':
    - match: compound
    - vault
    - vault.roles.apps
    - vault.roles.aws
    - vault.roles.bootcamps
    - vault.roles.micromasters
    - vault.roles.mitx
    - vault.roles.operations
    - vault.roles.pki
  'G@roles:elasticsearch and P@environment:(rc|production)-apps':
    - match: compound
    - elasticsearch.apps
    - nginx
    - nginx.apps_es
    - datadog.nginx-integration
  'G@roles:elasticsearch and P@environment:mitx(pro)?-(qa|production)':
    - match: compound
    - elasticsearch.mitx
  'G@roles:elasticsearch and G@environment:operations':
    - match: compound
    - elastic_stack.elasticsearch.logging_production
    - netdata.elasticsearch_logging
    - elastic_stack.beats
    - fluentd.elasticsearch
    - consul.elasticsearch
  'G@roles:elasticsearch and G@environment:operations-qa':
    - match: compound
    - elastic_stack.elasticsearch.logging_qa
    - netdata.elasticsearch_logging
    - fluentd.elasticsearch
    - consul.elasticsearch
  'P@roles:(edx|edx-worker)$':
    - match: compound
    - edx
    - edx.ansible_vars
    - edx.ansible_vars.cloud_deployment
    - edx.scheduled_jobs
    - fluentd.mitx
    - datadog.nginx-integration
    - datadog.supervisord-integration
  'P@roles:(edx|edx-worker) and not G@edx_codename:tumbleweed':
    - match: compound
    - edx.ansible_vars.theme
  'G@roles:sandbox and P@environment:mitx(pro)?-qa':
    - match: compound
    - edx
    - edx.sandbox
    - edx.ansible_vars
    - edx.ansible_vars.theme
  'P@roles:(edx|edx-worker|sandbox) and P@environment:mitxpro.*':
    - match: compound
    - edx.mitxpro
    - edx.ansible_vars.xpro
  'P@roles:(edx|edx-worker) and G@environment:mitx-qa':
    - match: compound
    - edx.ansible_vars.residential
    - edx.ansible_vars.residential_qa
    - edx.mitx-qa
    - edx.inotify_mitx
  'purpose:continuous-delivery':
    - match: grain
    - edx.mitx-koa
  'P@roles:(edx|edx-worker) and G@environment:mitx-production':
    - match: compound
    - edx.ansible_vars.residential
    - edx.mitx-production
    - edx.inotify_mitx
  'P@purpose:.*-draft and P@environment:mitx-(qa|production)':
    - match: compound
    - consul.mitx-draft
  'P@purpose:.*-live and P@environment:mitx-(qa|production)':
    - match: compound
    - consul.mitx-live
  'P@purpose:.*next-residential.*':
    - match: compound
    - edx.ansible_vars.next_residential
    - edx.mitx-koa
  'G@edx_codename:koa':
    - match: compound
    - edx.ansible_vars.koa
    - edx.mitx-koa
  'roles:xqwatcher':
    - match: grain
    - edx.xqwatcher
    - fluentd.xqwatcher
  'lightsail-xqwatcher-686':
    - match: glob
    - edx.xqwatcher
    - edx.xqwatcher_686
  'xqwatcher-600x*':
    - match: glob
    - edx.xqwatcher_600
  'xqwatcher-686*':
    - match: glob
    - edx.xqwatcher_686_residential
  'xqwatcher-6S082*':
    - match: glob
    - edx.xqwatcher_6S082
  'xqwatcher-940*':
    - match: glob
    - edx.xqwatcher_940
  'roles:amps-redirect':
    - match: grain
    - nginx
    - nginx.amps_redirect
    - nginx.mitxpro_redirect
    - nginx.chalkradio_redirect
    - letsencrypt.amps_redirect
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
    - consul.devstack
    - mongodb.devstack
    - mysql.devstack
    - elasticsearch.devstack
    - rabbitmq.devstack
  'roles:rabbitmq':
    - match: grain
    - rabbitmq
    - fluentd.rabbitmq
    - consul.rabbitmq
  'G@roles:rabbitmq and P@environment:(mitxpro-production|mitx-production|production-apps)':
    - match: compound
    - datadog.rabbitmq-integration
  'roles:tika':
    - match: grain
    - nginx
    - nginx.tika
  'roles:ocw-cms':
    - match: grain
    - logrotate.ocw_cms
    - fluentd.ocw_cms
    - apps.ocw
  'roles:ocw-mirror':
    - match: grain
    - fluentd.ocw_mirror
    - apps.ocw
    - logrotate.ocw_mirror
  'G@roles:ocw-mirror and G@ocw-environment:production':
    - match: compound
    - nginx
    - nginx.ocw_mirror
  'roles:ocw-origin':
    - match: grain
    - apps.ocw
    - letsencrypt.ocw_origin
    - nginx
    - nginx.ocw_origin
    - fluentd.ocw_origin
  'P@roles:ocw-(cms|mirror|origin) and G@ocw-environment:production':
    - match: compound
    - apps.ocw-production
  'P@roles:ocw-(cms|mirror|origin) and G@ocw-environment:qa':
    - match: compound
    - apps.ocw-qa
  'roles:ocw-db':
    - match: grain
    - logrotate.ocw_cms
    - fluentd.ocw_db
  'P@roles:ocw-(cms|db|origin|mirror) and G@ocw-environment:production':
    - datadog
  'G@roles:ocw-build and G@environment:production-apps':
    - match: compound
    - apps.ocw-next-production
    - caddy
    - caddy.ocw_build
  'G@roles:ocw-build and G@environment:rc-apps':
    - match: compound
    - apps.ocw-next-qa
    - caddy
    - caddy.ocw_build
  'roles:ocw-build':
    - match: grain
    - logrotate.ocw_build
    - vector.ocw_build
