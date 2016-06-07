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
  'roles:kibana':
    - match: grain
    - elasticsearch
    - elasticsearch.plugins
    - elasticsearch.kibana
    - elasticsearch.kibana.nginx_extra_config
  'roles:fluentd':
    - match: grain
    - fluentd
    - fluentd.plugins
    - fluentd.config
  'G@roles:edx_sandbox and G@sandbox_status:ami-provision':
    - match: compound
    - edx.sandbox_ami
