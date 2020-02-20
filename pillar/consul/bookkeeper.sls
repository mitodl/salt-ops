consul:
  extra_configs:
    bookkeeper_service:
      service:
        name: bookkeeper
        port: 3181
        check:
          tcp: localhost:3181
          interval: 10s
