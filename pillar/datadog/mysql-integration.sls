{% set environment = salt.grains.get('environment') %}

datadog:
  integrations:
    mysql:
      settings:
        instances:
          - server: mysql.service.consul
            user: __vault__:cache:mysql-{{ environment }}/creds/datadog>data>username
            pass: __vault__:cache:mysql-{{ environment }}/creds/datadog>data>password
            tags:
              - {{ environment }}
