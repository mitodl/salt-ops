datadog:
  integrations:
    cassandra:
      settings:
        instances:
          - host: localhost
            port: 7199
            name: {{ salt.grains.get('id') }}
