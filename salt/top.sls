base:
  '*':
    - utils.install_libs
    - vector
  'P@environment:(operations|operations-qa|mitx-qa|mitx-production|rc-apps|production-apps)':
    - match: compound
    - consul
    - consul.dns_proxy
  'roles:xqwatcher':
    - match: grain
    - edx.xqwatcher
    - vector
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
  'roles:rabbitmq':
    - match: grain
    - rabbitmq
    - rabbitmq.tests
    - vector
  'roles:reddit':
    - match: grain
    - utils.file_limits
    - pgbouncer
    - reddit
    - vector
    - nginx
    - nginx.certificates
  'roles:cassandra':
    - match: grain
    - cassandra
  'G@roles:mitx-cas':
    - match: compound
    - utils.configure_debian_source_repos
    - consul
    - python
    - node
    - nginx-shibboleth
    - django
    - uwsgi
    - vector
  'roles:ocw-origin':
    - match: grain
    - utils.configure_debian_source_repos
    - nginx
    - nginx.certificates
    - letsencrypt
    - apps.ocw.ocw-origin.install
    - apps.ocw.sync_repo
    - apps.ocw.symlinks_origin
  'roles:ocw-cms':
    - match: grain
    - utils.logrotate
    - apps.ocw.engines
    - apps.ocw.cms_plone
    - apps.ocw.sync_repo
    - apps.ocw.symlinks_cms
  'roles:ocw-db':
    - match: grain
    - utils.logrotate
  'roles:ocw-mirror':
    - match: grain
    - apps.ocw.mirror
    - apps.ocw.sync_repo
    - utils.logrotate
  'G@roles:ocw-mirror and G@ocw-environment:production':
    - match: compound
    - nginx
    - nginx.certificates
