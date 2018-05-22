consul:
  overrides:
    version: 1.1.0
  extra_configs:
    rabbitmq_service:
      service:
        name: rabbitmq
        port: 5672
        check:
          tcp: 'localhost:5672'
          interval: 10s
