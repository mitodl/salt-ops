{% set ENVIRONMENT = salt.grains.get('environment', 'dev') %}
{% set mm_postgres = salt.vault.read('postgresql-micromasters/creds/readonly') %}
{% set bootcamp_postgres = salt.vault.read('postgresql-bootcamps/creds/readonly') %}
{% set ovs_postgres = salt.vault.read('postgres-production-apps-odlvideo/creds/readonly') %}
{% set od_postgres = salt.vault.read('postgresql-production-apps-opendiscussions/creds/readonly') %}
{% set reddit_postgres = salt.vault.read('postgresql-production-apps-reddit/creds/readonly') %}
{% set mm_es = salt.vault.read('secret-micromasters/production/elasticsearch-auth-key').data.value.split(':') %}

redash:
  data_sources:
    - name: MicroMasters
      type: pg
      options:
        dbname: micromasters
        host: micromasters-db-read-replica.cbnm7ajau6mi.us-east-1.rds.amazonaws.com
        port: 15432
        user: {{ mm_postgres.data.username }}
        password: {{ mm_postgres.data.password }}
    - name: BootCamp Ecommerce
      type: pg
      options:
        dbname: bootcamps
        host: postgresql-bootcamps.service.production-apps.consul
        port: 5432
        user: {{ bootcamp_postgres.data.username }}
        password: {{ bootcamp_postgres.data.password }}
    - name: ODL Video Service
      type: pg
      options:
        dbname: odlvideo
        host: postgres-odlvideo.service.production-apps.consul
        port: 5432
        user: {{ ovs_postgres.data.username }}
        password: {{ ovs_postgres.data.password }}
    - name: Open Discussions
      type: pg
      options:
        dbname: opendiscussions
        host: postgresql-opendiscussions.service.production-apps.consul
        port: 5432
        user: {{ od_postgres.data.username }}
        password: {{ od_postgres.data.password }}
    - name: Open Discussions Reddit
      type: pg
      options:
        dbname: reddit
        host: postgresql-reddit.service.production-apps.consul
        port: 5432
        user: {{ reddit_postgres.data.username }}
        password: {{ reddit_postgres.data.password }}
    - name: MicroMasters ElasticSearch
      type: elasticsearch
      options:
        basic_auth_user: {{ mm_es[0] }}
        basic_auth_password: {{ mm_es[1] }}
        server: https://micromasters-es.odl.mit.edu
