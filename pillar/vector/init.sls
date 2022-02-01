{% set ENVIRONMENT = salt.grains.get('environment', 'dev') %}
vector:
  configuration:
    sources:
      host_metrics:
        type: host_metrics
        scrape_interval_secs: 60
        collectors:
          - cpu
          - disk
          - filesystem
          - load
          - host
          - memory
          - network

    transforms:
      host_metrics_relabel:
        type: remap
        inputs:
        - host_metrics
        source: |
          .tags.job = "integrations/linux_host"

      add_labels_to_metrics:
        type: remap
        inputs:
        - '*metrics_relabel'
        source: |
          .tags.environment = "{{ ENVIRONMENT }}"

    sinks:
      grafana_cortex_metrics:
        inputs:
        - add_labels_to_metrics
        type: prometheus_remote_write
        endpoint: https://prometheus-prod-10-prod-us-central-0.grafana.net/api/prom/push
        healthcheck: false
        auth:
          strategy: basic
          user: __vault__::secret-operations/global/grafana-cloud-credentials>data>prometheus_user
          password: __vault__::secret-operations/global/grafana-cloud-credentials>data>api_key
