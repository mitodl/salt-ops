{% set ENVIRONMENT = salt.grains.get('environment', 'dev') %}
{% set mm_es = salt.vault.read('secret-micromasters/production/elasticsearch-auth-key').data.value.split(':') %}
{% set discussions_es = salt.vault.read('secret-operations/production-apps/discussions/elasticsearch-auth-key').data.value.split(':') %}
{% set heroku_api_key = salt.vault.read('secret-operations/global/heroku/api_key').data.value %}
{% set xpro_rc_pg = salt.heroku.list_app_config_vars('xpro-rc', api_key=heroku_api_key)['DATABASE_URL'] %}
{% set xpro_rc_db_user, xpro_rc_db_pass = xpro_rc_pg.split('/')[-2].split('@')[0].split(':') %}
{% set xpro_rc_db_host, xpro_rc_db_port = xpro_rc_pg.split('/')[-2].split('@')[1].split(':') %}

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
    - name: MIT Open ElasticSearch
      type: elasticsearch
      options:
        basic_auth_user: {{ discussions_es[0] }}
        basic_auth_password: {{ discussions_es[1] }}
        server: https://elasticsearch-production-apps.odl.mit.edu/discussions_course_default
    - name: MicroMasters ElasticSearch
      type: elasticsearch
      options:
        basic_auth_user: {{ mm_es[0] }}
        basic_auth_password: {{ mm_es[1] }}
        server: https://elasticsearch-production-apps.odl.mit.edu/micromasters_private_enrollment_default
    - name: MITxPro RC
      type: pg
      options:
        dbname: {{ xpro_rc_pg.split('/')[-1] }}
        host: {{ xpro_rc_db_host }}
        port: {{ xpro_rc_db_port }}
        user: {{ xpro_rc_db_user }}
        password: {{ xpro_rc_db_pass }}
    - name: MITxPro Production
      type: pg
      options:
        dbname: mitxpro
        host: postgres-mitxpro.service.production-apps.consul
        port: 5432
        user: __vault__:cache:postgres-production-apps-mitxpro/creds/readonly>data>username
        password: __vault__:cache:postgres-production-apps-mitxpro/creds/readonly>data>password
    - name: Redash Metadata
      type: pg
      options:
        dbname: redash
        host: postgres-redash.service.consul
        port: 5432
        user: __vault__:cache:postgres-operations-redash/creds/readonly>data>username
        password: __vault__:cache:postgres-operations-redash/creds/readonly>data>password
