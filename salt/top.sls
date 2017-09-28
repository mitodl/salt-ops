base:
  '*':
    - utils.install_pip
  'not G@roles:devstack':
    - match: compound
    - utils.inotify_watches
    - fluentd
    - fluentd.plugins
    - fluentd.config
  'roles:xqwatcher':
    - match: grain
    - edx.xqwatcher
    - fluentd
    - fluentd.plugins
    - fluentd.config
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
    - rabbitmq.autocluster
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
  'roles:aggregator':
    - match: grain
    - fluentd.reverse_proxy
    - datadog.plugins
  'roles:kibana and G@environment:operations':
    - match: compound
    - elasticsearch.kibana
    - elasticsearch.kibana.nginx_extra_config
    - elasticsearch.elastalert
    - datadog.plugins
  'P@environment:(operations|mitx-production)':
    - match: compound
    - datadog
    - datadog.plugins
  'G@roles:elasticsearch and G@environment:micromasters':
    - match: compound
    - elasticsearch
    - elasticsearch.plugins
    - nginx.ng
    - datadog
    - datadog.plugins
  'G@roles:edx_sandbox and G@sandbox_status:ami-provision':
    - match: compound
    - edx.sandbox_ami
  'G@roles:mongodb and P@environment:mitx-(qa|rp|production)':
    - match: compound
    - mongodb
    - mongodb.consul_check
  'G@roles:mongodb and G@environment:mitx-production':
    - match: compound
    - datadog.plugins
  'P@environment:(operations|mitx-qa|mitx-production|rc-apps|production-apps)':
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
    - datadog.plugins
  'G@roles:edx and P@environment:mitx-(qa|rp|production)':
    - match: compound
    - edx.prod
    - edx.run_ansible
    - edx.gitreload
    - edx.patch_nginx
    - edx.edxapp_global_pre_commit
    - edx.tests
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
    - rabbitmq.configure
    - edx.django_user
