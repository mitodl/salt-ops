base:
  '*':
    - utils.install_libs
    - vector
  'P@environment:(operations|operations-qa|rc-apps|production-apps)':
    - match: compound
    - consul
    - consul.dns_proxy
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
