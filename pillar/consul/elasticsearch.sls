consul:
  extra_configs:
    elasticsearch:
      service:
        name: elasticsearch
        port: 9200
        {% if 'operations' in salt.grains.get('environment') %}
        tags:
          - logging
        {% endif %}
        check:
          tcp: 'localhost:9200'
          interval: 10s
          timeout: 3s
