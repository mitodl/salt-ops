{% set environment = salt.grains.get('environment', 'data-qa') %}
{% set bigquery_creds = salt.vault.read('secret-operations/data/institutional-research-bigquery-service-account').data.value %}

dagster:
  pipeline_configs:
    mitx_bigquery:
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
        bigquery_db:
          config: {{ bigquery_creds|json }}
      solids:
        download_user_data:
          config:
            last_modified_days: 5
            outputs_dir: "s3://mitodl-data-lake/mitx-enrollments/"
