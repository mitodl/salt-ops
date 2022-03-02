base:
  '* and not proxy-*':
    - match: compound
    - common
    - environment_settings
    # - vector
  # '* and not proxy-* and not restore-* and not G@roles:devstack and not P@environment:mitxonline and not G@context:packer and not P@roles:(edx|edx-worker)$':
  #   - match: compound
  #   - fluentd
  'P@environment:(rc.*|.*-qa)':
    - match: compound
    - elastic_stack.version_qa
  'not P@environment:(rc.*|.*-qa)':
    - match: compound
    - elastic_stack.version_production
  'roles:auth_server':
    - match: grain
    - vector.cas
  'G@roles:elasticsearch and not P@environment:operations*':
    - match: compound
    - fluentd.elasticsearch
    - consul
    - consul.elasticsearch
  'roles:kibana':
    - match: grain
    - mitca
    - elastic_stack.kibana
    - elastic_stack.beats
    - nginx
    - nginx.kibana
    - elastalert
    - logrotate.kibana
  'roles:master':
    - match: grain
    - master
    - master.config
    - elastic_stack.beats
    - master.api
    - caddy
    - caddy.master
    - vault.roles.apps
    - vault.roles.aws
    - vault.roles.bootcamps
    - vault.roles.micromasters
    - vault.roles.mitx
    - vault.roles.operations
    - vault.roles.pki
  master-operations-production:
    - master.production_schedule
  master-operations-qa:
    - master.qa_schedule
  'roles:dagster':
    - match: grain
    - dagster
    - dagster.xpro_edx
    - dagster.residential_edx
    - dagster.mitx_enrollments
    - dagster.mit_open
    - dagster.mitxonline_edx
    - consul
    - caddy
    - caddy.dagster
  'roles:fluentd':
    - match: grain
    - fluentd
  'G@roles:fluentd-server and G@environment:operations-qa':
    - match: compound
    - consul.fluentd
    - fluentd.server_operations_qa
  'G@roles:fluentd-server and G@environment:operations':
    - match: compound
    - consul.fluentd
    - fluentd.server
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
  proxy-bootcamps-*:
    - heroku.bootcamps
  proxy-mitxpro-*:
    - heroku.xpro
  proxy-mit-open-discussions-*:
    - heroku.discussions
  proxy-mitxonline-*:
    - heroku.mitxonline
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
  'roles:cassandra':
    - match: grain
    - cassandra
    - consul.cassandra
  'roles:reddit':
    - match: grain
    - nginx
    - nginx.reddit
    - reddit
    - vector.reddit
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
  'P@environment:(mitx-qa|mitx-production|mitxpro-qa|mitxpro-production|mitx-online-qa|mitx-online-production|operations|rc-apps|production-apps|micromasters)':
    - match: compound
    - consul
  'P@environment:.*apps.*':
    - match: compound
    - consul.apps
  'P@environment:.*mitxpro.*':
    - match: compound
    - consul.xpro
  'P@environment:mitx(pro|-online)?-(qa|production)':
    - match: compound
    - consul.mitx
  'P@environment:(operations|data)(-qa|-production)?':
    - match: compound
    - consul.operations
  'environment:operations':
    - match: grain
    - consul.operations
  'P@environment:(rc|production)-apps':
    - match: compound
    - rabbitmq.apps
    - consul.apps
  'G@roles:edx-analytics and P@environment:mitx(pro)?-production':
    - match: compound
    - data.mitx_etl
  'G@roles:elasticsearch and P@environment:(rc|production)-apps':
    - match: compound
    - elastic_stack.elasticsearch
    - elastic_stack.elasticsearch.apps
    - nginx
    - nginx.apps_es
  'G@roles:elasticsearch and P@environment:mitxpro-production':
    - match: compound
    - elasticsearch.mitx
  'G@roles:elasticsearch and P@environment:mitxpro-qa':
    - match: compound
    - elasticsearch.mitx
  'G@roles:elasticsearch and P@environment:(mitx-qa|mitxonline-qa|mitxonline-production|mitx-production)':
    - match: compound
    - elastic_stack.elasticsearch
    - elastic_stack.elasticsearch.mitx
  'G@roles:elasticsearch and G@environment:operations':
    - match: compound
    - elastic_stack.elasticsearch.logging_production
    - netdata.elasticsearch_logging
    - fluentd.elasticsearch
    - consul.elasticsearch
  'G@roles:elasticsearch and G@environment:operations-qa':
    - match: compound
    - elastic_stack.elasticsearch.logging_qa
    - netdata.elasticsearch_logging
    - fluentd.elasticsearch
    - consul.elasticsearch
  'roles:xqwatcher':
    - match: grain
    - edx.xqwatcher
    - vector.xqwatcher
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
  'roles:rabbitmq':
    - match: grain
    - rabbitmq
    - vector.rabbitmq
    - consul.rabbitmq
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
