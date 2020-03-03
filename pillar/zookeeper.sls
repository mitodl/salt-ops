zookeeper:
  version: 3.5.6
  user: zookeeper
  group: zookeeper
  max_heap_size: {{ salt.grains.get('mem_total') // 1.5 | int }}
