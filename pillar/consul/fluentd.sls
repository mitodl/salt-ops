consul:
  extra_configs:
    fluentd:
      services:
        - name: fluentd
          port: 5001
          check:
            tcp: '[::1]:5001'
            interval: 10s
        - name: log-aggregator
          port: 5001
          check:
            tcp: '[::1]:5001'
            interval: 10s
