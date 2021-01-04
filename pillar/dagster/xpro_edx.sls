{% set environment = salt.grains.get('environment', 'data-qa') %}
{% set xpro_map = {
    'data-qa': {
        'xpro_environment': 'mitxpro-qa',
        'xpro_purpose': 'xpro-qa'
    },
    'data-production': {
        'xpro_environment': 'mitxpro-production',
        'xpro_purpose': 'xpro-production'
    }
} %}
{% set xpro_purpose = xpro_map[environment].xpro_purpose %}
{% set xpro_environment = xpro_map[environment].xpro_environment %}

dagster:
  pipeline_configs:
    xpro_edx:
      execution:
        multiprocess:
          config:
            max_concurrent: {{ salt.grains.get('num_cpus') * 2 }}
      storage:
        s3:
          config:
            s3_bucket: dagster-{{ environment }}
            s3_prefix: pipeline-storage/xpro_edx
      resources:
        results_dir:
          config:
            outputs_directory_date_format: '%Y%m%d'
        healthchecks:
          config:
            check_id: __vault__::secret-data/{{ environment }}/pipelines/edx/xpro/healthchecks-io-check-id>data>value
        sqldb:
          config:
            mysql_db_name: edxapp_{{ xpro_purpose|replace('-', '_') }}
            mysql_hostname: edxapp-mysql.service.{{ xpro_environment }}.consul
            mysql_username: __vault__:cache:mariadb-mitxpro-edxapp-{{ xpro_environment }}/creds/readonly>data>username
            mysql_password: __vault__:cache:mariadb-mitxpro-edxapp-{{ xpro_environment }}/creds/readonly>data>password
      solids:
        export_edx_forum_database:
          config:
            edx_mongodb_forum_database_name: forum_{{ xpro_purpose|replace('-', '_') }}
            edx_mongodb_host: mongodb-master.service.{{ xpro_environment }}.consul
            edx_mongodb_password: __vault__:cache:mongodb-{{ xpro_environment }}/creds/forum-{{ xpro_purpose }}>data>password
            edx_mongodb_username: __vault__:cache:mongodb-{{ xpro_environment }}/creds/forum-{{ xpro_purpose }}>data>username
            edx_mongodb_auth_db: forum_{{ xpro_purpose|replace('-', '_') }}
        edx_upload_daily_extracts:
          config:
            edx_etl_results_bucket: mitx-etl-{{ xpro_purpose }}-{{ xpro_environment }}
        list_edx_courses:
          config:
            edx_token_type: bearer
            edx_base_url: __vault__::secret-data/{{ environment }}/pipelines/edx/xpro/edx-oauth-client>data>url
            edx_client_id: __vault__::secret-data/{{ environment }}/pipelines/edx/xpro/edx-oauth-client>data>id
            edx_client_secret: __vault__::secret-data/{{ environment }}/pipelines/edx/xpro/edx-oauth-client>data>secret
