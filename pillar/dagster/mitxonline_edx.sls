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
            edx_mongodb_host: mongodb-master.service.{{ mitxonline_environment }}.consul
            edx_mongodb_password: __vault__:cache:mongodb-mitxonline/creds/forum>data>password
            edx_mongodb_username: __vault__:cache:mongodb-mitxonline/creds/forum>data>username
            edx_mongodb_auth_db: forum
        edx_upload_daily_extracts:
          config:
            edx_etl_results_bucket: ol-data-lake-{{ mitxonline_environment }}/edxapp/extracts/
        list_edx_courses:
          config:
            edx_base_url: __vault__::secret-data/{{ environment }}/pipelines/edx/mitxonline/edx-oauth-client>data>url
            edx_client_id: __vault__::secret-data/{{ environment }}/pipelines/edx/mitxonline/edx-oauth-client>data>id
            edx_client_secret: __vault__::secret-data/{{ environment }}/pipelines/edx/mitxonline/edx-oauth-client>data>secret
