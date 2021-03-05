{% set environment = salt.grains.get('environment', 'data-qa') %}
{% set env_suffix = environment.split('-')[-1] %}
{% set bucket = "s3://ol-data-lake-mitx-" ~ env_suffix %}
{% set bigquery_creds = salt.vault.read('secret-operations/data/institutional-research-bigquery-service-account').data.value %}

dagster:
  pipeline_configs:
    mitx_bigquery:
      resources:
        io_manager:
          config:
            s3_bucket: dagster-{{ environment }}
            s3_prefix: pipeline-storage/xpro_edx
        bigquery_db:
          config: {{ bigquery_creds|json }}
      solids:
        download_user_data:
          config:
            last_modified_days: 5
            outputs_dir: {{ bucket }}/mitx-enrollments/
