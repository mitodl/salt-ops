consul:
  extra_configs:
    edx_services:
      services:
        - name: xqueue-{{ salt.grains.get('purpose') }}
          port: 18040
          check:
            http: 'http://localhost:18040/xqueue/status'
            interval: 30s
        - name: gitreload-{{ salt.grains.get('purpose') }}
          port: 8095
          check:
            tcp: 'localhost:8095'
            interval: 30s
        - name: lms
          port: 8040
          tags:
            - edxapp
          check:
            tcp: 'localhost:8040'
            interval: 10s
