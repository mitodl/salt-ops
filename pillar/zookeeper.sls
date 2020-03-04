{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set release_id = salt.sdb.get('sdb://consul/zookeeper/' ~ ENVIRONMENT ~ '/release-id') %}
{% if not release_id %}
{% set release_id = 'v1' %}
{% endif %}

zookeeper:
  version: 3.5.7
  user: zookeeper
  group: zookeeper
  quorum_listen: True
  max_heap_size: {{ salt.grains.get('mem_total') // 1.5 | int }}
  nodes:
    - zookeeper-{{ ENVIRONMENT }}-0-{{ release_id }}.zookeeper.service.consul
    - zookeeper-{{ ENVIRONMENT }}-1-{{ release_id }}.zookeeper.service.consul
    - zookeeper-{{ ENVIRONMENT }}-2-{{ release_id }}.zookeeper.service.consul
