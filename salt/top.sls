base:
  '*':
    - utils.install_pip
  'P@environment:(operations|dogwood-qa|dogwood-rp|rp|partners)':
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
  'roles:kibana':
    - match: grain
    - elasticsearch
    - elasticsearch.plugins
    - elasticsearch.kibana
    - elasticsearch.kibana.nginx_extra_config
    - datadog.plugins
  'roles:fluentd':
    - match: grain
    - fluentd
    - fluentd.plugins
    - fluentd.config
  'G@roles:edx_sandbox and G@sandbox_status:ami-provision':
    - match: compound
    - edx.sandbox_ami
  'G@roles:mongodb and P@environment:(dogwood-qa|dogwood-rp)':
    - match: compound
    - mongodb
    - mongodb.consul_check
    - datadog.plugins
  'roles:aggregator':
    - match: grain
    - fluentd.reverse_proxy
    - datadog.plugins
  'P@environment:(operations|dogwood-qa|dogwood-rp)':
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
  'G@roles:rabbitmq and P@environment:(dogwood-qa|dogwood-rp)':
    - match: compound
    - rabbitmq
    - rabbitmq.autocluster
    - rabbitmq.tests
    - datadog.plugins
  'G@roles:edx and P@environment:(dogwood-qa|dogwood-rp)':
    - match: compound
    - edx.gitreload
    - edx.prod
    - fluentd
    - fluentd.plugins
    - fluentd.config
