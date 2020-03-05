{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set zk_release_id = salt.sdb.get('sdb://consul/zookeeper/' ~ ENVIRONMENT ~ '/release-id') %}
{% if not zk_release_id %}
{% set zk_release_id = 'v1' %}
{% endif %}

pulsar:
  services:
    - broker
    - proxy
  config:
    broker.conf:
      clusterName: {{ ENVIRONMENT }}
      advertiseAddress: pulsar.service.consul
      bindAddress: 0.0.0.0
      configurationStoreServers: zookeeper-{{ ENVIRONMENT }}-0-{{ zk_release_id }}.zookeeper.service.consul:2181,zookeeper-{{ ENVIRONMENT }}-1-{{ zk_release_id }}.zookeeper.service.consul:2181,zookeeper-{{ ENVIRONMENT }}-2-{{ zk_release_id }}.zookeeper.service.consul:2181
      zookeeperServers: zookeeper-{{ ENVIRONMENT }}-0-{{ zk_release_id }}.zookeeper.service.consul:2181,zookeeper-{{ ENVIRONMENT }}-1-{{ zk_release_id }}.zookeeper.service.consul:2181,zookeeper-{{ ENVIRONMENT }}-2-{{ zk_release_id }}.zookeeper.service.consul:2181
      functionsWorkerEnabled: "true"
    proxy.conf:
      brokerServiceURL: pulsar://pulsar.service.consul:6650
      brokerWebServiceURL: http://pulsar.service.consul:8080
      functionWorkerWebServiceURL: http://pulsar-functions.service.consul:8080
    functions_worker.yaml:
      numFunctionPackageReplicas: 3
      pulsarFunctionsCluster: {{ ENVIRONMENT }}
