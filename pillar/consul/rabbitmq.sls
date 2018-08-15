consul:
  extra_configs:
    rabbitmq_service:
      service:
        name: rabbitmq
        port: 5672
        check:
          tcp: 'localhost:5672'
          interval: 10s
