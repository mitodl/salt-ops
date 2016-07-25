base:
  '*':
    - utils.install_pip
  'G@environment:(operations|dogwood-qa|dogwood-rp|rp|partners)':
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
  'G@roles:mongodb and G@environment:dogwood-qa':
    - match: compound
    - mongodb
    - datadog.plugins
  'roles:aggregator':
    - match: grain
    - fluentd.reverse_proxy
    - datadog.plugins
  'P@environment:(operations|dogwood-qa)':
    - match: compound
    - consul
    - consul.dns_proxy
    - consul.tests
    - consul.tests.test_dns_setup
  'G@roles:consul_server and G@environment:operations':
    - match: compound
    - consul
    - consul.tests
    - consul.dns_proxy
    - consul.tests.test_dns_setup
    - datadog.plugins
  'G@roles:vault_server and G@environment:operations':
    - match: compound
    - vault
    - vault.tests
  'G@roles:rabbitmq and G@environment:dogwood-qa':
    - match: compound
    - rabbitmq
    - rabbitmq.autocluster
    - rabbitmq.tests
    - datadog.plugins
  'G@roles:edx and G@environment:dogwood-qa':
    - match: compound
    - edx.prod
    - edx.gitreload
