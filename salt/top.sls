base:
  '*':
  'roles:master':
    - match: grain
    - master
    - master.aws
    - master.api
    - master_utils.contrib
  'roles:elasticsearch':
    - match: grain
    - elasticsearch
    - elasticsearch.plugins
  'roles:kibana':
    - match: grain
    - elasticsearch
    - elasticsearch.kibana
  'roles:fluentd':
    - match: grain
    - fluentd
    - fluentd.plugins
    - fluentd.config
