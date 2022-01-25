base:
  '*':
    - utils.install_libs
    - vector
  'P@environment:(operations|operations-qa|mitx-qa|mitx-production|mitxpro-qa|mitxpro-production|mitxonline-qa|mitxonline-production|rc-apps|production-apps|data-qa|data-production)':
    - match: compound
    - consul
    - consul.dns_proxy
  'roles:xqwatcher':
    - match: grain
    - edx.xqwatcher
  'roles:amps-redirect':
    - match: grain
    - letsencrypt
    - nginx
  'roles:backups':
    - match: grain
    - backups.backup
  'roles:master':
    - match: grain
    - master
    - master.api
    - master_utils.dns
    - master_utils.libgit
    - heroku.proxy_config
    - caddy
  'G@roles:master and P@environment:operations(-qa)?':
    - match: compound
    - master.aws
    - master_utils.dns
  'G@roles:elasticsearch and P@environment:operations(-qa)?':
    - match: compound
    - utils.file_limits
    - elastic-stack.elasticsearch
    - elastic-stack.elasticsearch.plugins
  'roles:rabbitmq':
    - match: grain
    - rabbitmq
    - rabbitmq.tests
  'roles:dagster':
    - match: grain
    - mongodb.repository
    - dagster
    - caddy
    - caddy.local_auth
  'roles:fluentd':
    - match: grain
    - fluentd
    - fluentd.plugins
    - fluentd.config
  'roles:log-aggregator':
    - match: grain
    - fluentd.reverse_proxy
  'roles:reddit':
    - match: grain
    - utils.file_limits
    - pgbouncer
    - reddit
    - nginx
    - nginx.certificates
  'roles:cassandra':
    - match: grain
    - cassandra
  starcellbio*:
    - consul
    - python
    - node
    - django
    - uwsgi
    - nginx
  'G@roles:odl-video-service or G@roles:mitx-cas':
    - match: compound
    - utils.configure_debian_source_repos
    - consul
    - python
    - node
    - nginx-shibboleth
    - django
    - uwsgi
  'roles:odl-video-service':
    - match: grain
    - utils.logrotate
  'roles:redash':
    - match: grain
    - utils.configure_debian_source_repos
    - consul
    - consul.dns_proxy
    - python
    - nginx-shibboleth
    - django.install
    - django.deploy
    - apps.redash.datasources
    - uwsgi
    - etl
    - etl.email_mapping
  'G@roles:kibana and P@environment:operations(-qa)?':
    - match: compound
    - elastic-stack.kibana
    - utils.mitca_pem
    - utils.configure_debian_source_repos
    - utils.logrotate
    - nginx
    - elastic-stack.elastalert
  'G@roles:elasticsearch and P@environment:micromasters':
    - match: compound
    - elasticsearch
    - elasticsearch.plugins
    - nginx
  'G@roles:elasticsearch and P@environment:(rc-apps|production-apps)':
    - match: compound
    - elastic-stack.elasticsearch
    - elastic-stack.elasticsearch.plugins
    - elastic_stack.elasticsearch.apps.cronjobs
    - nginx
  'G@roles:elasticsearch and P@environment:(mitx-qa|mitxonline-qa|mitxonline-production|mitx-production)':
    - match: compound
    - elastic-stack.elasticsearch
    - elastic-stack.elasticsearch.plugins
  'G@roles:elasticsearch and P@environment:mitxpro-qa':
    - match: compound
    - elasticsearch
    - elasticsearch.plugins
  'G@roles:elasticsearch and P@environment:mitxpro-production':
    - match: compound
    - elasticsearch
    - elasticsearch.plugins
  'G@roles:edx-analytics and P@environment:mitx(pro)?-production':
    - match: compound
    - etl
    - etl.mitx
  'roles:tika':
    - match: grain
    - nginx
    - tika
  'roles:ocw-origin':
    - match: grain
    - utils.configure_debian_source_repos
    - nginx
    - nginx.certificates
    - letsencrypt
    - fluentd
    - fluentd.plugins
    - fluentd.config
    - apps.ocw.ocw-origin.install
    - apps.ocw.sync_repo
    - apps.ocw.symlinks_origin
  'roles:ocw-cms':
    - match: grain
    - fluentd
    - fluentd.plugins
    - fluentd.config
    - utils.logrotate
    - apps.ocw.engines
    - apps.ocw.cms_plone
    - apps.ocw.sync_repo
    - apps.ocw.symlinks_cms
  'roles:ocw-db':
    - match: grain
    - fluentd
    - fluentd.plugins
    - fluentd.config
    - utils.logrotate
  'roles:ocw-mirror':
    - match: grain
    - fluentd
    - fluentd.plugins
    - fluentd.config
    - apps.ocw.mirror
    - apps.ocw.sync_repo
    - utils.logrotate
  'G@roles:ocw-mirror and G@ocw-environment:production':
    - match: compound
    - nginx
    - nginx.certificates
  'roles:ocw-build':
    - match: grain
    - vector
    - node
    - caddy
    - apps.ocw.nextgen_build_install
    - utils.logrotate
