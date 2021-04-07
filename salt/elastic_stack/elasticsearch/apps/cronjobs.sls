
ensure_installation_of_jq:
  pkg.installed:
    - name: jq

manage_search_index_pruning_job:
  cron.present:
    - identifier: PRUNE_SEARCH_INDICES
    - user: root
    - hour: random
    - minute: random
    - name: >-
       for index in `curl -s 'localhost:9200/_aliases' | jq 'to_entries |
       map(select(.value.aliases == {}) | .key) | .[]' | sed s'/"//g'`;
       do curl -X DELETE localhost:9200/$index; done > /var/tmp/prune-search-idx.log 2>&1

{% if salt.grains.get('environment') == 'rc-apps' %}
manage_ci_index_pruning_job:
  cron.present:
    - identifier: PRUNE_CI_INDICES
    - user: root
    - hour: 6
    - minute: random
    - day: 6
    - name: >-
      for index in `curl -s localhost:9200/_cat/indices/*-ci* | awk '{print $3}'`;
      do curl -X DELETE localhost:9200/$index; done > /var/tmp/prune-ci-idx.log 2>&1
{% endif %}
