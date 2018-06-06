consul:
  overrides:
    version: 0.9.3
  extra_configs:
    rabbitmq_service:
      service:
        name: rabbitmq
        port: 5672
        check:
          tcp: 'localhost:5672'
          interval: 10s
