{% set rds_endpoint = salt.boto_rds.get_endpoint('bootcamps-rds-postgresql') %}

consul:
  extra_configs:
    hosted_services:
      services:
        - name: bootcamps-db
          port: {{ rds_endpoint.split(':')[1] }}
          address: {{ rds_endpoint.split(':')[0] }}
          check:
            tcp: '{{ rds_endpoint }}'
            interval: 10s
