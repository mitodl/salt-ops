pulsar:
  services:
    - broker
    - proxy
  config:
    broker.conf:
      clusterName: {{ environment }}
      advertiseAddress: pulsar.service.consul
      bindAddress: 0.0.0.0
      configurationStoreServers: zookeeper.service.consul
      zookeeperServers: zookeeper.service.consul
      functionsWorkerEnabled: "true"
    proxy.conf:
      brokerServiceURL: pulsar://pulsar.service.consul:6650
      brokerWebServiceURL: http://pulsar.service.consul:8080
      functionWorkerWebServiceURL: http://pulsar-functions.service.consul:8080
    functions_worker.yaml:
      numFunctionPackageReplicas: 3
      pulsarFunctionsCluster: {{ environment }}
