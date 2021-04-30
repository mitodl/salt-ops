consul:
  extra_configs:
    edx_forum_service:
      services:
        - name: forum-{{ salt.grains.get('purpose') }}
          port: 4567
          check:
            http: 'http://localhost:4567'
            interval: 30s
