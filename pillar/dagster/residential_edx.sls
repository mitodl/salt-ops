{% set environment = salt.grains.get('environment', 'data-qa') %}
{% set mitx_map = {
    'data-qa': {
        'mitx_environment': 'mitx-qa',
        'mitx_purpose': 'current-residential-live'
    },
    'data-production': {
        'mitx_environment': 'mitx-production',
        'mitx_purpose': 'residential-live'
    }
} %}
{% set mitx_purpose = mitx_map[environment].mitx_purpose %}
{% set mitx_environment = mitx_map[environment].mitx_environment %}

dagster:
  pipeline_configs:
    residential_edx:
      execution:
        multiprocess:
          config:
            max_concurrent: {{ salt.grains.get('num_cpus') * 2 }}
      storage:
        s3:
          config:
            s3_bucket: dagster-{{ environment }}
            s3_prefix: pipeline-storage/residential_edx
      resources:
        results_dir:
          config:
            outputs_directory_date_format: '%Y%m%d'
        healthchecks:
          config:
            check_id: __vault__::secret-data/{{ environment }}/pipelines/edx/residential/healthchecks-io-check-id>data>value
        sqldb:
          config:
            mysql_db_name: edxapp_{{ mitx_purpose|replace('-', '_') }}
            mysql_hostname: mysql.service.{{ mitx_environment }}.consul
            mysql_username: __vault__:cache:mysql-{{ mitx_environment }}/creds/readonly>data>username
            mysql_password: __vault__:cache:mysql-{{ mitx_environment }}/creds/readonly>data>password
      solids:
        export_edx_forum_database:
          config:
            edx_mongodb_forum_database_name: forum_{{ mitx_purpose|replace('-', '_') }}
            edx_mongodb_host: mongodb-master.service.{{ mitx_environment }}.consul
            edx_mongodb_password: __vault__:cache:mongodb-{{ mitx_environment }}/creds/forum-{{ mitx_purpose }}>data>password
            edx_mongodb_username: __vault__:cache:mongodb-{{ mitx_environment }}/creds/forum-{{ mitx_purpose }}>data>username
        edx_upload_daily_extracts:
          config:
            edx_etl_results_bucket: mitx-etl-{{ mitx_purpose }}-{{ mitx_environment }}
        list_edx_courses:
          config:
            edx_base_url: __vault__::secret-data/{{ environment }}/pipelines/edx/residential/edx-oauth-client>data>url
            edx_client_id: __vault__::secret-data/{{ environment }}/pipelines/edx/residential/edx-oauth-client>data>id
            edx_client_secret: __vault__::secret-data/{{ environment }}/pipelines/edx/residential/edx-oauth-client>data>secret
