{% set environment = salt.grains.get('environment', 'data-qa') %}
{% set env_suffix = environment.split('-')[-1] %}
{% set bucket = "s3://ol-data-lake-mit-open-" ~ env_suffix %}
{% set open_env_map = {
  'data-qa': 'rc-apps',
  'data-production': 'production-apps'
} %}

dagster:
  execution:
    multiprocess:
      config:
        max_concurrent: 4
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
            outputs_dir: {{ bucket }}/processed/mit-open-course-runs/
        fetch_open_user_data:
          config:
            outputs_dir: {{ bucket }}/raw/mit-open-application-db/auth_user/
        fetch_open_course_data:
          config:
            outputs_dir: {{ bucket }}/processed/mit-open-courses/
    open-discussions-enrollment-update:
      resources:
        athena_db:
          config:
            schema_name: ol_warehouse_mit_open_{{ env_suffix }}
            work_group: ol-warehouse-{{ env_suffix }}
        postgres_db:
          config:
            postgres_db_name: opendiscussions
            postgres_hostname: {{ open_env_map[environment] }}-rds-postgresql-opendiscussions.cbnm7ajau6mi.us-east-1.rds.amazonaws.com
            postgres_password: __vault__:cache:postgres-{{ open_env_map[environment] }}-opendiscussions/creds/opendiscussions>data>password
            postgres_port: 5432
            postgres_username: __vault__:cache:postgres-{{ open_env_map[environment] }}-opendiscussions/creds/opendiscussions>data>username
      solids:
        fetch_open_run_data:
          config:
            outputs_dir: {{ bucket }}/processed/mit-open-course-runs/
        fetch_open_user_data:
          config:
            outputs_dir: {{ bucket }}/raw/mit-open-application-db/auth_user/
        fetch_open_course_data:
          config:
            outputs_dir: {{ bucket }}/processed/mit-open-courses/
        run_open_enrollments_query:
           config:
             athena_mitx_database: ol_warehouse_mitx_{{ env_suffix }}
             athena_mitx_enrollments_table: raw_bigquery_mitx_data_user_info_combo
             athena_open_course_runs_table: mit_open_course_runs
             athena_open_courses_table: mit_open_courses
             athena_open_database: ol_warehouse_mit_open_{{ env_suffix }}
             athena_open_users_table: raw_mit_open_application_db_auth_users
