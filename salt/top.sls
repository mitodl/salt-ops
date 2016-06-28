base:
  '*':
    - datadog
  'roles:master':
    - match: grain
    - master
    - master.aws
    - master.api
    - master_utils.contrib
    - master_utils.dns
    - master_utils.libgit
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
  'roles:aggregator':
    - match: grain
    - fluentd.reverse_proxy
    - datadog.plugins
  'environment:dogwood-qa':
    - match: grain
    - consul
    - consul.tests
  'G@roles:consul_server and G@environment:operations':
    - match: compound
    - consul
    - consul.tests
  'G@roles:vault_server and G@environment:operations':
    - match: compound
    - vault
    - vault.tests
