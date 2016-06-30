base:
  'roles:master':
    - match: grain
    - master
    - master.api
    - master_utils.contrib
    - master_utils.libgit
  'G@roles:master and G@environment:operations':
    - match: compound
    - master.aws
    - master_utils.dns
  'roles:elasticsearch':
    - match: grain
    - elasticsearch
    - elasticsearch.plugins
    - datadog
    - datadog.plugins
  'roles:kibana':
    - match: grain
    - elasticsearch
    - elasticsearch.plugins
    - elasticsearch.kibana
    - elasticsearch.kibana.nginx_extra_config
    - datadog
    - datadog.plugins
  'roles:fluentd':
    - match: grain
    - fluentd
    - fluentd.plugins
    - fluentd.config
    - datadog
  'G@roles:edx_sandbox and G@sandbox_status:ami-provision':
    - match: compound
    - edx.sandbox_ami
  'roles:aggregator':
    - match: grain
    - fluentd.reverse_proxy
    - datadog
    - datadog.plugins
  'environment:dogwood-qa':
    - match: grain
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
  'G@roles:vault_server and G@environment:operations':
    - match: compound
    - vault
    - vault.tests
