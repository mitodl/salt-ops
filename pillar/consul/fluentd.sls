consul:
  extra_configs:
    fluentd:
      services:
        - name: fluentd
          port: 5001
          tags:
            - logging
          check:
            tcp: 'localhost:5001'
            interval: 10s
        - name: log-aggregator
          port: 5001
          tags:
            - logging
          check:
            tcp: 'localhost:5001'
            interval: 10s
