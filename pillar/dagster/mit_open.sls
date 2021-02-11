{% set environment = salt.grains.get('environment', 'data-qa') %}
{% set bigquery_creds = salt.vault.read('secret-operations/data/institutional-research-bigquery-service-account').data.value %}

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
            host: postgres-opendiscussions.service.production-apps.consul
            password: __vault__:cache:postgres-{{ environment }}-opendiscussions/creds/readonly>data>password
            port: 5432
            user: __vault__:cache:postgres-{{ environment }}-opendiscussions/creds/readonly>data>username
      solids:
        download_run_data:
          config:
            outputs_dir: s3://mitodl-data-lake/enrollments/open/
            file_base: run_data
        download_user_data:
          config:
            file_base: user_data
            outputs_dir: s3://mitodl-data-lake/enrollments/open/
