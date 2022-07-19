{% set ENVIRONMENT = salt.grains.get('environment', 'dev') %}
{% set mm_es = salt.vault.read('secret-micromasters/production/elasticsearch-auth-key').data.value.split(':') %}
{% set discussions_es = salt.vault.read('secret-operations/production-apps/discussions/elasticsearch-auth-key').data.value.split(':') %}
{% set heroku_api_key = salt.vault.read('secret-operations/global/heroku/mitx-devops-api-key').data.value %}
{% set xpro_rc_pg = salt.heroku.list_app_config_vars('xpro-rc', api_key=heroku_api_key)['DATABASE_URL'] %}
{% set xpro_rc_db_user, xpro_rc_db_pass = xpro_rc_pg.split('/')[-2].split('@')[0].split(':') %}
{% set xpro_rc_db_host, xpro_rc_db_port = xpro_rc_pg.split('/')[-2].split('@')[1].split(':') %}

{% set micromasters_rc_pg = salt.heroku.list_app_config_vars('micromasters-rc', api_key=heroku_api_key)['DATABASE_URL'] %}
{% set micromasters_rc_db_user, micromasters_rc_db_pass = micromasters_rc_pg.split('/')[-2].split('@')[0].split(':') %}
{% set micromasters_rc_db_host, micromasters_rc_db_port = micromasters_rc_pg.split('/')[-2].split('@')[1].split(':') %}

{% set mitxonline_rc_pg = salt.heroku.list_app_config_vars('mitxonline-rc', api_key=heroku_api_key)['DATABASE_URL'] %}
{% set mitxonline_rc_db_user, mitxonline_rc_db_pass = mitxonline_rc_pg.split('/')[-2].split('@')[0].split(':') %}
{% set mitxonline_rc_db_host, mitxonline_rc_db_port = mitxonline_rc_pg.split('/')[-2].split('@')[1].split(':') %}

{% set ovs_rds_endpoint = salt.boto_rds.get_endpoint('production-apps-rds-postgres-odlvideo').split(":")[0] %}
{% set reddit_rds_endpoint = salt.boto_rds.get_endpoint('production-apps-rds-postgresql-reddit').split(":")[0] %}
{% set xpro_rds_endpoint = salt.boto_rds.get_endpoint('production-apps-rds-postgres-mitxpro').split(":")[0] %}
{% set discussions_rds_endpoint = salt.boto_rds.get_endpoint('production-apps-rds-postgresql-opendiscussions').split(":")[0] %}

redash:
  data_sources:
    - name: MicroMasters
      type: pg
      options:
        dbname: micromasters
        host: micromasters-db-read-replica.cbnm7ajau6mi.us-east-1.rds.amazonaws.com
        port: 15432
        sslmode: require
        user: __vault__:cache:postgresql-micromasters/creds/readonly>data>username
        password: __vault__:cache:postgresql-micromasters/creds/readonly>data>password
    - name: MicroMasters RC
      type: pg
      options:
        sslmode: require
        dbname: {{ micromasters_rc_pg.split('/')[-1] }}
        host: {{ micromasters_rc_db_host }}
        port: {{ micromasters_rc_db_port }}
        user: {{ micromasters_rc_db_user }}
        password: {{ micromasters_rc_db_pass }}
    - name: Bootcamp Ecommerce
      type: pg
      options:
        dbname: bootcamp_ecommerce
        host: bootcamps-rds-postgresql.cbnm7ajau6mi.us-east-1.rds.amazonaws.com
        port: 5432
        sslmode: require
        user: __vault__:cache:postgresql-bootcamps/creds/readonly>data>username
        password: __vault__:cache:postgresql-bootcamps/creds/readonly>data>password
    - name: ODL Video Service
      type: pg
      options:
        dbname: odlvideo
        host: {{ ovs_rds_endpoint }}
        port: 5432
        sslmode: require
        user: __vault__:cache:postgres-production-apps-odlvideo/creds/readonly>data>username
        password: __vault__:cache:postgres-production-apps-odlvideo/creds/readonly>data>password
    - name: Open Discussions
      type: pg
      options:
        dbname: opendiscussions
        host: {{ discussions_rds_endpoint }}
        port: 5432
        sslmode: require
        user: __vault__:cache:postgres-production-apps-opendiscussions/creds/readonly>data>username
        password: __vault__:cache:postgres-production-apps-opendiscussions/creds/readonly>data>password
    - name: Open Discussions Reddit
      type: pg
      options:
        dbname: reddit
        host: {{ reddit_rds_endpoint }}
        port: 5432
        sslmode: require
        user: __vault__:cache:postgres-production-apps-reddit/creds/readonly>data>username
        password: __vault__:cache:postgres-production-apps-reddit/creds/readonly>data>password
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
        sslmode: require
        dbname: {{ xpro_rc_pg.split('/')[-1] }}
        host: {{ xpro_rc_db_host }}
        port: {{ xpro_rc_db_port }}
        user: {{ xpro_rc_db_user }}
        password: {{ xpro_rc_db_pass }}
    - name: MITxPro Production
      type: pg
      options:
        dbname: mitxpro
        host: {{ xpro_rds_endpoint }}
        port: 5432
        sslmode: require
        user: __vault__:cache:postgres-production-apps-mitxpro/creds/readonly>data>username
        password: __vault__:cache:postgres-production-apps-mitxpro/creds/readonly>data>password
    - name: MITx Online Production
      type: pg
      options:
        dbname: mitxonline
        host: mitxonline-production-app-db.cbnm7ajau6mi.us-east-1.rds.amazonaws.com
        port: 5432
        sslmode: require
        user: __vault__:cache:postgres-mitxonline/creds/readonly>data>username
        password: __vault__:cache:postgres-mitxonline/creds/readonly>data>password
    - name: MITx Online RC
      type: pg
      options:
        sslmode: require
        dbname: {{ mitxonline_rc_pg.split('/')[-1] }}
        host: {{ mitxonline_rc_db_host }}
        port: {{ mitxonline_rc_db_port }}
        user: {{ mitxonline_rc_db_user }}
        password: {{ mitxonline_rc_db_pass }}
    - name: OCW Studio Production
      type: pg
      options:
        dbname: ocw_studio
        host: ocw-studio-db-applications-production.cbnm7ajau6mi.us-east-1.rds.amazonaws.com
        port: 5432
        sslmode: require
        user: __vault__:cache:postgres-ocw-studio-applications-production/creds/readonly>data>username
        password: __vault__:cache:postgres-ocw-studio-applications-production/creds/readonly>data>password
    - name: Redash Metadata
      type: pg
      options:
        dbname: redash
        host: postgres-redash.service.consul
        port: 5432
        sslmode: require
        user: __vault__:cache:postgres-operations-redash/creds/readonly>data>username
        password: __vault__:cache:postgres-operations-redash/creds/readonly>data>password
