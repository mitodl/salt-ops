{% set environment = salt.grains.get('environment', 'data-qa') %}
{% set mitxonline_map = {
    'data-qa': {
        'mitxonline_environment': 'mitxonline-qa',
        'mongodb_uri': 'mongodb://mitxonline-mitxonline-q-shard-00-00.5zw8v.mongodb.net:27017,mitxonline-mitxonline-q-shard-00-01.5zw8v.mongodb.net:27017,mitxonline-mitxonline-q-shard-00-02.5zw8v.mongodb.net:27017/?ssl=true&authSource=admin&replicaSet=atlas-2z2o2h-shard-0'
    },
    'data-production': {
        'mitxonline_environment': 'mitxonline-production',
        'mongodb_uri': 'mongodb://mitxonline-mitxonline-p-shard-00-00.z2ka1.mongodb.net:27017,mitxonline-mitxonline-p-shard-00-01.z2ka1.mongodb.net:27017,mitxonline-mitxonline-p-shard-00-02.z2ka1.mongodb.net:27017,mitxonline-mitxonline-p-shard-00-03.z2ka1.mongodb.net:27017,mitxonline-mitxonline-p-shard-00-04.z2ka1.mongodb.net:27017/?ssl=true&authSource=admin&replicaSet=atlas-rxrinr-shard-0'
    }
} %}
{% set mitxonline_environment = mitxonline_map[environment].mitxonline_environment %}
{% set env_suffix=environment.split('-')[-1] %}
{% set rds_endpoint = salt.boto_rds.get_endpoint('edxapp-db-mitx-{env_suffix}'.format(env_suffix=env_suffix)) %}
{% set MYSQL_HOST = rds_endpoint.split(':')[0] %}

dagster:
  pipeline_configs:
    mitxonline_edx:
      resources:
        io_manager:
          config:
            s3_bucket: dagster-{{ environment }}
            s3_prefix: pipeline-storage/mitxonline-edxapp
        results_dir:
          config:
            outputs_directory_date_format: '%Y%m%d'
        healthchecks:
          config:
            check_id: __vault__::secret-data/{{ environment }}/pipelines/edx/mitxonline/healthchecks-io-check-id>data>value
        sqldb:
          config:
            mysql_db_name: edxapp
            mysql_hostname: edxapp-db.service.{{ mitxonline_environment }}.consul
            mysql_username: __vault__:cache:mariadb-mitxonline/creds/readonly>data>username
            mysql_password: __vault__:cache:mariadb-mitxonline/creds/readonly>data>password
      ops:
        export_edx_forum_database:
          config:
            edx_mongodb_forum_database_name: forum
            edx_mongodb_uri: {{ mitxonline_map[environment]['mongodb_uri'] }}
            edx_mongodb_password: __vault__::secret-mitxonline/mongodb-forum>data>password
            edx_mongodb_username: __vault__::secret-mitxonline/mongodb-forum>data>username
            edx_mongodb_auth_db: admin
        edx_upload_daily_extracts:
          config:
            edx_etl_results_bucket: mitx-etl-{{ mitxonline_environment }}
        list_edx_courses:
          config:
            edx_base_url: __vault__::secret-data/{{ environment }}/pipelines/edx/mitxonline/edx-oauth-client>data>url
            edx_client_id: __vault__::secret-data/{{ environment }}/pipelines/edx/mitxonline/edx-oauth-client>data>id
            edx_client_secret: __vault__::secret-data/{{ environment }}/pipelines/edx/mitxonline/edx-oauth-client>data>secret
        edx_export_courses:
          config:
            edx_base_url: __vault__::secret-data/{{ environment }}/pipelines/edx/mitxonline/edx-oauth-client>data>url
            edx_client_id: __vault__::secret-data/{{ environment }}/pipelines/edx/mitxonline/edx-oauth-client>data>id
            edx_client_secret: __vault__::secret-data/{{ environment }}/pipelines/edx/mitxonline/edx-oauth-client>data>secret
            edx_studio_base_url: __vault__::secret-data/{{ environment }}/pipelines/edx/mitxonline/edx-oauth-client>data>studio_url
            edx_course_bucket: {{ mitxonline_map[environment].mitxonline_environment }}-edxapp-courses
