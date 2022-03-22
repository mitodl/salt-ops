{% set environment = salt.grains.get('environment', 'data-qa') %}
{% set env_suffix = environment.split('-')[-1] %}
{% set bucket = "s3://ol-data-lake-mit-open-" ~ env_suffix %}
{% set env_map = {
  'data-qa': 'rc-apps',
  'data-production': 'production-apps'
} %}

dagster:
  pipeline_configs:
    micromasters:
      resources:
        postgres_db:
          config:
            postgres_db_name: micromasters
            postgres_hostname: micromasters-db-read-replica.cbnm7ajau6mi.us-east-1.rds.amazonaws.com
            postgres_password: __vault__:cache:postgresql-micromasters/creds/readonly>data>password
            postgres_port: 5432
            postgres_username: __vault__:cache:postgresql-micromasters/creds/readonly>data>username
      ops:
        download_user_data:
          config:
            last_modified_days: 5
            outputs_dir: {{ bucket }}/bigquery-mitx-data/user-info-combo/
