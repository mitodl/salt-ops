{% set environment = salt.grains.get('environment', 'data-qa') %}
{% set env_suffix = environment.split('-')[-1] %}
{% set bucket = "s3://ol-data-lake-mit-open-" ~ env_suffix %}
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
            outputs_dir: {{ bucket }}/mit-open-application-db/mit-open-course-runs/
        fetch_open_user_data:
          config:
            outputs_dir: {{ bucket }}/mit-open-application-db/mit-open-users/
        fetch_open_course_data:
          config:
            outputs_dir: {{ bucket }}/mit-open-application-db/mit-open-courses/
