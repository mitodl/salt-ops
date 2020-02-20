consul:
  extra_configs:
    zookeeper_service:
      service:
        name: zookeeper
        port: 2181
        check:
          tcp: localhost:2181
          interval: 10s
