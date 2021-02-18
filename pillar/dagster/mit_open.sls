{% set environment = salt.grains.get('environment', 'data-qa') %}
{% set open_env_map = {
  'data-qa': 'rc-apps',
  'data-production': 'production-apps'
} %}

dagster:
  pipeline_configs:
    open-discussions:
      resources:
        postgres_db:
          config:
            postgres_db_name: opendiscussions
            postgres_hostname: {{ open_env_map[environment] }}-rds-postgresql-opendiscussions.cbnm7ajau6mi.us-east-1.rds.amazonaws.com
            postgres_password: __vault__:cache:postgres-{{ open_env_map[environment] }}-opendiscussions/creds/readonly>data>password
            postgres_port: 5432
            postgres_username: __vault__:cache:postgres-{{ open_env_map[environment] }}-opendiscussions/creds/readonly>data>username
      solids:
        fetch_open_run_data:
          config:
            outputs_dir: s3://mitodl-data-lake/mit-open/course-runs/
            file_base: run_data
        fetch_open_user_data:
          config:
            file_base: user_data
            outputs_dir: s3://mitodl-data-lake/mit-open/users/
