vector:
  configuration:
    api:
      enabled: true
    sources:
      vector_agents:
        type: vector
        address: 0.0.0.0:9000
    sinks:
      es_cluster:
        inputs:
          - vector_agents
        type: elasticsearch
        endpoint: 'http://operations-elasticsearch.query.consul:9200'
        index: "logstash-\{\{ environment \}\}-%Y.%W"
        healthcheck: false
