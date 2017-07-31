base:
  '*':
    - utils.install_pip
  'not G@roles:devstack':
    - match: compound
    - utils.inotify_watches
    - fluentd
    - fluentd.plugins
    - fluentd.config
  'P@environment:(operations|mitx-rp|mitx-production)':
    - match: compound
    - datadog
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
  'roles:kibana and G@environment:operations':
    - match: compound
    - elasticsearch.kibana
    - elasticsearch.kibana.nginx_extra_config
    - elasticsearch.elastalert
    - datadog.plugins
  'G@roles:elasticsearch and G@environment:micromasters':
    - match: compound
    - elasticsearch
    - elasticsearch.plugins
    - nginx.ng
    - datadog
    - datadog.plugins
  'roles:fluentd':
    - match: grain
    - fluentd
    - fluentd.plugins
    - fluentd.config
  'G@roles:edx_sandbox and G@sandbox_status:ami-provision':
    - match: compound
    - edx.sandbox_ami
  'G@roles:mongodb and P@environment:mitx-(qa|rp|production)':
    - match: compound
    - mongodb
    - mongodb.consul_check
    - datadog.plugins
  'roles:aggregator':
    - match: grain
    - fluentd.reverse_proxy
    - datadog.plugins
  'P@environment:(operations|mitx-qa|mitx-rp|mitx-production)':
    - match: compound
    - consul
    - consul.dns_proxy
    - consul.tests
    - consul.tests.test_dns_setup
  'G@roles:consul_server and G@environment:operations':
    - match: compound
    - datadog.plugins
  'G@roles:vault_server and G@environment:operations':
    - match: compound
    - vault
    - vault.tests
    - utils.file_limits
  'G@roles:rabbitmq and P@environment:mitx-(qa|rp|production)':
    - match: compound
    - rabbitmq
    - rabbitmq.autocluster
    - rabbitmq.tests
    - datadog.plugins
  'G@roles:edx and P@environment:mitx-(qa|rp|production)':
    - match: compound
    - edx.prod
    - edx.run_ansible
    - edx.gitreload
    - edx.tests
    - edx.maintenance_tasks
    - fluentd
    - fluentd.plugins
    - fluentd.config
  'G@roles:edx and G@environment:mitx-production':
    - match: compound
    - utils.ssh_users
  'G@roles:edx-worker and P@environment:mitx-(qa|rp|production)':
    - match: compound
    - edx.prod
    - edx.run_ansible
    - fluentd
    - fluentd.plugins
    - fluentd.config
  'roles:xqwatcher':
    - match: grain
    - edx.xqwatcher
  'roles:backups':
    - match: grain
    - backups.backup
  'roles:restores':
    - match: grain
    - backups.restore
  'G@roles:devstack and P@environment:dev':
    - match: compound
    - consul
    - consul.dns_proxy
    - consul.tests
    - consul.tests.test_dns_setup
    - mysql
    - mysql.remove_test_database
    - mongodb
    - mongodb.consul_check
    - rabbitmq
    - elasticsearch
    - edx.prod
    - edx.run_ansible
    - edx.tests
