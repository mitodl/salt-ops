{% set environment = salt.grains.get('environment', 'data-qa') %}
{% set mitxonline_map = {
    'data-qa': {
        'mitxonline_environment': 'mitxonline-qa',
    },
    'data-production': {
        'mitxonline_environment': 'mitxonline-production',
    }
} %}
{% set mitxonline_environment = mitxonline_map[environment].mitxonline_environment %}
{% set env_suffix=environment.split('-')[-1] %}
{% set rds_endpoint = salt.boto_rds.get_endpoint('edxapp-db-mitx-{env_suffix}'.format(env_suffix=env_suffix)) %}
{% set MYSQL_HOST = rds_endpoint.split(':')[0] %}

dagster:
  pipeline_configs:
    mitxonline_edx:
      execution:
        multiprocess:
          config:
            max_concurrent: {{ salt.grains.get('num_cpus') * 2 }}
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
      solids:
        export_edx_forum_database:
          config:
            edx_mongodb_forum_database_name: forum
            edx_mongodb_host: {{ salt.consul.get(key="mitxonline/mongodb/host") }}
            edx_mongodb_password: __vault__::secret-mitxonline/mongodb-forum>data>password
            edx_mongodb_username: __vault__::secret-mitxonline/mongodb-forum>data>username
            edx_mongodb_auth_db: admin
        edx_upload_daily_extracts:
          config:
            edx_etl_results_bucket: ol-data-lake-{{ mitxonline_environment }}/edxapp/extracts/
        list_edx_courses:
          config:
            edx_base_url: __vault__::secret-data/{{ environment }}/pipelines/edx/mitxonline/edx-oauth-client>data>url
            edx_client_id: __vault__::secret-data/{{ environment }}/pipelines/edx/mitxonline/edx-oauth-client>data>id
            edx_client_secret: __vault__::secret-data/{{ environment }}/pipelines/edx/mitxonline/edx-oauth-client>data>secret
