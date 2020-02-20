consul:
  extra_configs:
    pulsar_service:
      service:
        name: pulsar
        port: 6650
        check:
          tcp: localhost:6650
          interval: 10s
