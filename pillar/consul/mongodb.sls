consul:
  extra_configs:
    mongodb_service:
      enable_script_checks: True
      services:
        - name: mongodb
          port: 27017
          tags:
            - mongodb
          check:
            tcp: 'localhost:27017'
            interval: 10s
        - name: mongodb-master
          port: 27017
          tags:
            - mongodb
            - master
          check:
            args:
              - /consul/scripts/mongo_is_master.sh
            interval: 10s
