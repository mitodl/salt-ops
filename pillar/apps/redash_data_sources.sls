{% set ENVIRONMENT = salt.grains.get('environment', 'dev') %}
{% set mm_es = salt.vault.read('secret-micromasters/production/elasticsearch-auth-key').data.value.split(':') %}

redash:
  data_sources:
    - name: MicroMasters
      type: pg
      options:
        dbname: micromasters
        host: micromasters-db-read-replica.cbnm7ajau6mi.us-east-1.rds.amazonaws.com
        port: 15432
        user: __vault__:cache:postgresql-micromasters/creds/readonly>data>username
        password: __vault__:cache:postgresql-micromasters/creds/readonly>data>password
    - name: Bootcamp Ecommerce
      type: pg
      options:
        dbname: bootcamp_ecommerce
        host: bootcamps-rds-postgresql.cbnm7ajau6mi.us-east-1.rds.amazonaws.com
        port: 5432
        user: __vault__:cache:postgresql-bootcamps/creds/readonly>data>username
        password: __vault__:cache:postgresql-bootcamps/creds/readonly>data>password
    - name: ODL Video Service
      type: pg
      options:
        dbname: odlvideo
        host: postgres-odlvideo.service.production-apps.consul
        port: 5432
        user: __vault__:cache:postgres-production-apps-odlvideo/creds/readonly>data>username
        password: __vault__:cache:postgres-production-apps-odlvideo/creds/readonly>data>password
    - name: Open Discussions
      type: pg
      options:
        dbname: opendiscussions
        host: postgresql-opendiscussions.service.production-apps.consul
        port: 5432
        user: __vault__:cache:postgresql-production-apps-opendiscussions/creds/readonly>data>username
        password: __vault__:cache:postgresql-production-apps-opendiscussions/creds/readonly>data>password
    - name: Open Discussions Reddit
      type: pg
      options:
        dbname: reddit
        host: postgresql-reddit.service.production-apps.consul
        port: 5432
        user: __vault__:cache:postgresql-production-apps-reddit/creds/readonly>data>username
        password: __vault__:cache:postgresql-production-apps-reddit/creds/readonly>data>password
    - name: MicroMasters ElasticSearch
      type: elasticsearch
      options:
        basic_auth_user: {{ mm_es[0] }}
        basic_auth_password: {{ mm_es[1] }}
        server: https://micromasters-elasticsearch.odl.mit.edu/micromasters_private_enrollment_default
