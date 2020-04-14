consul:
  extra_configs:
    dremio_service:
      services:
        - name: dremio-web
          port: 9047
          check:
            tcp: localhost:9047
            interval: 10s
        - name: dremio-odbc
          port: 31010
          check:
            tcp: localhost:31010
            interval: 10s
        - name: dremio-node
          port: 45678
          check:
            tcp: localhost:45678
            interval: 10s
