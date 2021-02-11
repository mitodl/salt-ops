{% set environment = salt.grains.get('environment', 'data-qa') %}
{% set open_env_map = {
  'data-qa': 'rc-apps',
  'data-production': 'production-apps'
} %}

dagster:
  pipeline_configs:
    open-discussions:
      execution:
        multiprocess:
          config:
            max_concurrent: {{ salt.grains.get('num_cpus') * 2 }}
      resources:
        postgres_db:
          config:
            dbname: opendiscussions
            host: postgres-opendiscussions.service.{{ open_env_map[environment] }}.consul
            password: __vault__:cache:postgres-{{ open_env_map[environment] }}-opendiscussions/creds/readonly>data>password
            port: 5432
            user: __vault__:cache:postgres-{{ open_env_map[environment] }}-opendiscussions/creds/readonly>data>username
      solids:
        download_run_data:
          config:
            outputs_dir: s3://mitodl-data-lake/mit-open/course-runs/
            file_base: run_data
        download_user_data:
          config:
            file_base: user_data
            outputs_dir: s3://mitodl-data-lake/mit-open/users/
