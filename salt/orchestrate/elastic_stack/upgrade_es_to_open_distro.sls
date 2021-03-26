{# USAGE:

    Before upgrading:
      1. Uninstall Elastalert from the Kibana minion
      2. Remove Index Lifecycle policies in Kibana
      3. Remove "index.lifecycle" objects from all indices' settings
         For example:
          curl -XPUT "http://es-host:9200/logs*/_settings" \
            -H 'Content-Type: application/json' \
            -d'{"index": { "lifecycle.*": null} }'
      4. Remove ILM-related index templates from Elasticsearch
      5. Shut down the Kibana service
      6. Delete the .kibana* indices from Elasticsearch

    Then ...

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

stop_elasticsearch:
  salt.function:
    - tgt: "{{ ES_NODE_TARGET }}"
    - name: service.stop
    - arg:
      - elasticsearch
    - require:
      - http: disable_shard_allocation

upgrade_elasticsearch:
  salt.state:
    - tgt: "{{ ES_NODE_TARGET }}"
    - sls:
      - elastic_stack.upgrade_es_to_open_distro.sls
    - require:
      - salt: stop_elasticsearch

start_elasticsearch:
  salt.function:
    - tgt: "{{ ES_NODE_TARGET }}"
    - name: service.start
    - arg:
      - elasticsearch
    - require:
      - salt: upgrade_elasticsearch

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
