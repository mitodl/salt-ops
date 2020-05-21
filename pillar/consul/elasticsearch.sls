consul:
  extra_configs:
    elasticsearch:
      service:
        name: elasticsearch
        port: 9200
        tags:
          - logging
        check:
          http: 'http://localhost:9200/'
          interval: 10s
