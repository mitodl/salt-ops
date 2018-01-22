consul:
  extra_configs:
    defaults:
      enable_syslog: True
      server: True
      bootstrap_expect: 1
      bind_addr: {{ grains['fqdn_ip4'][0] }}
      dns_config:
        allow_stale: True
        node_ttl: 30s
        service_ttl:
          "*": 30s
    mongodb_service:
      service:
        name: mongodb
        port: 27017
        check:
          tcp: 'localhost:27017'
          interval: 10s
    mysql_service:
      service:
        name: mysql
        port: 3306
        check:
          tcp: 'localhost:3306'
          interval: 10s
    rabbitmq_service:
      service:
        name: rabbitmq
        port: 5672
        check:
          tcp: 'localhost:5672'
          interval: 10s
    elasticsearch_service:
      service:
        name: elasticsearch
        port: 9200
        check:
          tcp: 'localhost:9200'
          interval: 10s
