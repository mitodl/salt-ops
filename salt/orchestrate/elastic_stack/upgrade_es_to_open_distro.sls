{# USAGE:
    Set ES_BASE_URL to your Elasticsearch URL.
    Set ES_NODE_TARGET to the Salt target for your Elasticsearch node minions.
    Set WAIT to the time to wait after restarting nodes and doing the next one.

    Example:
      sudo -E \
        ES_BASE_URL=http://mycluster:9200 \
        ES_NODE_TARGET="elasticsearch-*" \
        WAIT=30 \
        salt-run state.orchestrate elastic_stack.upgrade_es_to_open_distro
#}

{% set ES_NODE_TARGET = salt.environ.get('ES_NODE_TARGET') %}
{% set ES_BASE_URL = salt.environ.get('ES_BASE_URL') %}
{% set WAIT = salt.environ.get('WAIT', '30') %}

disable_shard_allocation:
  http.query:
    - name: {{ ES_BASE_URL }}/_cluster/settings
    - method: PUT
    - status: 200
    - data: >-
        {
          "persistent": {
            "cluster.routing.allocation.enable": "none"
          }
        }
    - header_dict:
        'Content-Type': 'application/json'
        'Accept': 'application/json'

upgrade_elasticsearch:
  salt.state:
    - tgt: "{{ ES_NODE_TARGET }}"
    - batch: 1
    - batch_wait: {{ WAIT | int }}
    - sls:
      - elastic_stack.upgrade_es_to_open_distro.sls
    - require:
      - http: disable_shard_allocation

enable_shard_allocation:
  http.query:
    - name: {{ ES_BASE_URL }}/_cluster/settings
    - method: PUT
    - status: 200
    - data: >-
        {
          "persistent": {
            "cluster.routing.allocation.enable": "all"
          }
        }
    - header_dict:
        'Content-Type': 'application/json'
        'Accept': 'application/json'

    - require:
      - salt: upgrade_elasticsearch
