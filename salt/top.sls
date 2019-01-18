base:
  '*':
    - utils.install_libs
  'not G@roles:devstack':
    - match: compound
    - utils.inotify_watches
    - fluentd
    - fluentd.plugins
    - fluentd.config
  'P@environment:(operations|mitx-qa|mitx-production|rc-apps|production-apps)':
    - match: compound
    - consul
    - consul.dns_proxy
    - consul.tests
    - consul.tests.test_dns_setup
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
    - nginx.ng
    - nginx.ng.certificates
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
  'G@roles:master and G@environment:operations':
    - match: compound
    - master.aws
    - master_utils.dns
  'roles:elasticsearch':
    - match: grain
    - elasticsearch
    - elasticsearch.plugins
    - datadog.plugins
  'roles:rabbitmq':
    - match: grain
    - rabbitmq
    - rabbitmq.tests
  'roles:consul_server':
    - match: grain
    - consul
    - consul.dns_proxy
    - consul.tests
    - consul.tests.test_dns_setup
  'roles:fluentd':
    - match: grain
    - fluentd
    - fluentd.plugins
    - fluentd.config
  'roles:log-aggregator':
    - match: grain
    - fluentd.reverse_proxy
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
    - nginx.ng
    - nginx.ng.certificates
  'roles:cassandra':
    - match: grain
    - cassandra
  starcellbio*:
    - consul
    - python
    - node
    - django
    - uwsgi
    - nginx.ng
  'G@roles:odl-video-service or G@roles:mitx-cas':
    - match: compound
    - utils.configure_debian_source_repos
    - consul
    - python
    - node
    - nginx-shibboleth
    - django
    - uwsgi
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
  'G@roles:kibana and G@environment:operations':
    - match: compound
    - elasticsearch.kibana
    - elasticsearch.kibana.nginx_extra_config
    - elasticsearch.elastalert
    - datadog.plugins
    - monit
  'P@environment:(operations|mitx-production)':
    - match: compound
    - datadog
    - datadog.plugins
  'environment:production-apps':
    - match: grain
    - datadog
    - datadog.plugins
  'G@roles:elasticsearch and P@environment:(micromasters|rc-apps|production-apps)':
    - match: compound
    - elasticsearch
    - elasticsearch.plugins
    - nginx.ng
  'G@roles:elasticsearch and P@environment:(micromasters|production-apps)':
    - match: compound
    - datadog
    - datadog.plugins
  'G@roles:mongodb and P@environment:mitx-(qa|rp|production)':
    - match: compound
    - mongodb
    - mongodb.consul_check
  'G@roles:mongodb and G@environment:mitx-production':
    - match: compound
    - datadog.plugins
  'G@roles:consul_server and G@environment:operations':
    - match: compound
    - datadog.plugins
    - vault
    - vault.tests
    - utils.file_limits
  'G@roles:rabbitmq and P@environment:mitx-(qa|rp|production)':
    - match: compound
    - datadog.plugins
  'G@roles:edx and P@environment:mitx-(qa|rp|production)':
    - match: compound
    - edx.prod
    - edx.run_ansible
    - edx.gitreload
    - edx.patch_nginx
    - edx.edxapp_global_pre_commit
    - edx.etc_hosts
    - edx.hacks
    - edx.tests
    - fluentd
    - fluentd.plugins
    - fluentd.config
  'G@roles:edx and G@environment:mitx-production':
    - match: compound
    - monit
    - utils.ssh_users
  'G@roles:edx-worker and P@environment:mitx-(qa|rp|production)':
    - match: compound
    - edx.prod
    - edx.run_ansible
    - fluentd
    - fluentd.plugins
    - fluentd.config
  'G@roles:analytics and G@environment:mitx-production':
    - match: compound
    - edx.mitx_etl
  'roles:ocw-origin':
    - match: grain
    - utils.configure_debian_source_repos
    - nginx.ng
    - nginx.ng.certificates
    - letsencrypt
    - apps.ocw.ocw-origin.install
  'roles:sandbox':
    - match: grain
    - edx.prod
    - edx.migration
    - edx.patch_nginx
    - edx.tests
    - edx.django_user
  'G@roles:devstack and P@environment:dev':
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
