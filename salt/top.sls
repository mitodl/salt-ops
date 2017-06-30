base:
  '*':
    - utils.install_pip
    - utils.inotify_watches
  'P@environment:(operations|mitx-rp|rp|partners)':
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
  'G@roles:mongodb and P@environment:(mitx-qa|mitx-rp)':
    - match: compound
    - mongodb
    - mongodb.consul_check
    - datadog.plugins
  'roles:aggregator':
    - match: grain
    - fluentd.reverse_proxy
    - datadog.plugins
  'P@environment:(operations|mitx-qa|mitx-rp)':
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
  'G@roles:rabbitmq and P@environment:(mitx-qa|mitx-rp)':
    - match: compound
    - rabbitmq
    - rabbitmq.autocluster
    - rabbitmq.tests
    - datadog.plugins
  'G@roles:edx and P@environment:(mitx-qa|mitx-rp)':
    - match: compound
    - edx.prod
    - edx.run_ansible
    - edx.gitreload
    - edx.tests
    - edx.maintenance_tasks
    - fluentd
    - fluentd.plugins
    - fluentd.config
  'G@roles:edx-worker and P@environment:(mitx-qa|mitx-rp)':
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
