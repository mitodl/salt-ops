{% set environment = salt.grains.get('environment', 'data-qa') %}
{% set env_suffix = environment.split('-')[-1] %}
{% set bucket = "s3://ol-data-lake-mitx-" ~ env_suffix ~ "/raw" %}
{% set bigquery_creds = salt.vault.read('secret-operations/data/institutional-research-bigquery-service-account').data.value %}
{% do bigquery_creds.pop('auth_provider_x509_cert_url') %}
{% do bigquery_creds.pop('type') %}

dagster:
  pipeline_configs:
    mitx_bigquery:
      resources:
        io_manager:
          config:
            s3_bucket: dagster-{{ environment }}
            s3_prefix: pipeline-storage/mitx-bigquery
        bigquery_db:
          config: {{ bigquery_creds|json }}
      ops:
        export_person_course:
          config:
            outputs_dir: /tmp/bigquery_person_course
            table_name: person_course
        export_user_info_combo:
          config:
            outputs_dir:  /tmp/bigquery_user_info_combo
            table_name: user_info_combo
