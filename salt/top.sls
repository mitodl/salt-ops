base:
  '*':
    - utils.install_libs
  'not G@roles:devstack and not G@roles:edx and not G@roles:mongodb':
    - match: compound
    - fluentd
    - fluentd.plugins
    - fluentd.config
  'P@environment:(operations|operations-qa|mitx-qa|mitx-production|mitxpro-qa|mitxpro-production|mitxonline-qa|mitxonline-production|rc-apps|production-apps|data-qa|data-production)':
    - match: compound
    - consul
    - consul.dns_proxy
  'roles:xqwatcher':
    - match: grain
    - edx.xqwatcher
    - fluentd
    - fluentd.plugins
    - fluentd.config
  'lightsail-xqwatcher-686':
    - match: glob
    - edx.xqwatcher
  'roles:amps-redirect':
    - match: grain
    - letsencrypt
    - nginx
  'roles:backups':
    - match: grain
    - backups.backup
  'roles:restores':
    - match: grain
    - backups.restore
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
    - datadog.plugins
  'roles:rabbitmq':
    - match: grain
    - rabbitmq
    - rabbitmq.tests
  'roles:zookeeper':
    - match: grain
    - zookeeper.set_host
    - zookeeper
    - zookeeper.server
  'roles:bookkeeper':
    - match: grain
    - bookkeeper
    - bookkeeper.tests
  'roles:pulsar':
    - match: grain
    - pulsar
    - pulsar.tests
  'roles:dagster':
    - match: grain
    - mongodb.repository
    - dagster
    - caddy
    - caddy.local_auth
  dremio*:
    - dremio
    - nginx
  'roles:consul_server':
    - match: grain
    - consul
    - consul.dns_proxy
    - caddy
  'roles:fluentd':
    - match: grain
    - fluentd
    - fluentd.plugins
    - fluentd.config
  'roles:log-aggregator':
    - match: grain
    - fluentd.reverse_proxy
  'G@roles:log-aggregator and P@environment:operations':
    - match: compound
    - datadog.plugins
  'roles:scylladb':
    - match: grain
    - scylladb.configure
    - scylladb.tests
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
  'roles:edx-video-pipeline':
    - match: grain
    - edx.run_ansible
  'roles:edx-video-worker':
    - match: grain
    - edx.run_ansible
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
    - datadog.plugins
  'P@environment:(operations|mitxpro-production|mitxonline-production) and not analytics-mitx*':
    - match: compound
    - datadog
    - datadog.plugins
  'environment:production-apps':
    - match: grain
    - datadog
    - datadog.plugins
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
  'G@roles:elasticsearch and P@environment:(micromasters|production-apps)':
    - match: compound
    - datadog
    - datadog.plugins
  'roles:mongodb':
    - match: grain
    - mongodb
    - mongodb.consul_check
    - vector
  'G@roles:mongodb and P@environment:mitx(pro|-online)?-production':
    - match: compound
    - datadog.plugins
  'G@roles:consul_server and P@environment:operations(-qa)?':
    - match: compound
    - datadog.plugins
    - vault
    - vault.tests
    - utils.file_limits
  'G@roles:rabbitmq and P@environment:mitx(pro|-online)?-(qa|production)':
    - match: compound
    - datadog.plugins
  'roles:edx':
    - match: grain
    - edx.prod
    - edx.run_ansible
    - edx.patch_nginx
    - edx.hacks
    - edx.tests
    - vector
  'G@roles:edx and P@environment:mitx-(qa|production)':
    - match: compound
    - edx.gitreload
    - edx.edxapp_global_pre_commit
    - edx.etc_hosts
    - edx.tests.test_gitreload
  'G@roles:edx and G@environment:mitx-production':
    - match: compound
    - utils.ssh_users
  'G@roles:edx-worker and P@environment:mitx(pro|-online)?-(qa|production)':
    - match: compound
    - edx.prod
    - edx.run_ansible
    - edx.hacks
    - fluentd
    - fluentd.plugins
    - fluentd.config
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
  'P@roles:ocw-(cms|db|origin|mirror) and G@ocw-environment:production':
    - datadog
  'roles:sandbox':
    - match: grain
    - edx.prod
    - edx.migration
    - edx.patch_nginx
    - edx.tests
    - edx.django_user
  'G@roles:devstack and G@environment:dev':
    - match: compound
    - consul
    - consul.dns_proxy
    - mysql
    - mysql.remove_test_database
    - mongodb
    - mongodb.consul_check
    - rabbitmq
    - edx.prod
    - rabbitmq.configure
    - edx.django_user
  'roles:ocw-build':
    - match: grain
    - vector
    - node
    - caddy
    - apps.ocw.nextgen_build_install
    - utils.logrotate
