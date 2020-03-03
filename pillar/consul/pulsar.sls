consul:
  extra_configs:
    pulsar_service:
      services:
        - name: pulsar-broker
          port: 6650
          check:
            tcp: localhost:6650
            interval: 10s
        - name: pulsar-proxy
          port: 8080
          check:
            tcp: localhost:8080
            interval: 10s
