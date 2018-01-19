consul:
  extra_configs:
    scylladb_service:
      service:
        name: scylladb
        port: 9180
        check:
          tcp: 'localhost:9180'
          interval: 10s
