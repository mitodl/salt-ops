pulsar:
  config:
    broker.conf:
      clusterName: {{ environment }}
      advertiseAddress: pulsar.service.consul
      bindAddress: 0.0.0.0
      configurationStoreServers: zookeeper.service.consul
      zookeeperServers: zookeeper.service.consul
