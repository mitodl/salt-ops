{% set environment = salt.grains.get('environment', 'data-qa') %}
{% set xpro_map = {
    'data-qa': {
        'xpro_environment': 'xpro-qa',
        'xpro_purpose': 'xpro-qa'
    },
    'data-production': {
        'xpro_environment': 'xpro-production',
        'xpro_purpose': 'xpro-production'
    }
} %}
{% set xpro_purpose = xpro_map[environment].xpro_purpose %}
{% set xpro_environment = xpro_map[environment].xpro_environment %}
{% set env_suffix=environment.split('-')[-1] %}
{% set rds_endpoint = salt.boto_rds.get_endpoint('edxapp-db-xpro-{env_suffix}'.format(env_suffix=env_suffix)) %}
{% set MYSQL_HOST = rds_endpoint.split(':')[0] %}

dagster:
  pipeline_configs:
    xpro_edx:
      execution:
        multiprocess:
          config:
            max_concurrent: {{ salt.grains.get('num_cpus') * 2 }}
      resources:
        io_manager:
          config:
            s3_bucket: dagster-{{ environment }}
            s3_prefix: pipeline-storage/xpro_edx
        results_dir:
          config:
            outputs_directory_date_format: '%Y%m%d'
        healthchecks:
          config:
            check_id: __vault__::secret-data/{{ environment }}/pipelines/edx/xpro/healthchecks-io-check-id>data>value
        sqldb:
          config:
            mysql_db_name: edxapp
            mysql_hostname: {{ MYSQL_HOST }}
            mysql_username: __vault__:cache:mariadb-xpro/creds/readonly>data>username
            mysql_password: __vault__:cache:mariadb-xpro/creds/readonly>data>password
      solids:
        export_edx_forum_database:
          config:
            edx_mongodb_forum_database_name: forum
            edx_mongodb_host: {{ consul.get(key="xpro/mongodb/host") }}
            edx_mongodb_password: __vault__:secret-xpro/mongodb-forum>data>password
            edx_mongodb_username: __vault__:secret-xpro/mongodb-forum>data>username
            edx_mongodb_auth_db: admin
        edx_upload_daily_extracts:
          config:
            edx_etl_results_bucket: mitx-etl-{{ xpro_purpose }}-mitxpro-{{ env_suffix }}
        list_edx_courses:
          config:
            edx_token_type: jwt
            edx_base_url: __vault__::secret-data/{{ environment }}/pipelines/edx/xpro/edx-oauth-client>data>url
            edx_client_id: __vault__::secret-data/{{ environment }}/pipelines/edx/xpro/edx-oauth-client>data>id
            edx_client_secret: __vault__::secret-data/{{ environment }}/pipelines/edx/xpro/edx-oauth-client>data>secret
