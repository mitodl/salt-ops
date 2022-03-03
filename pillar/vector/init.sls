vector:
  # This list only applies if there is not a more specific vector:configurations
  # defined elsewhere. If there is, and you would like to include these elements as well,
  # you will need to explicitly state them again.
  configurations: 
  - host_metrics
  - auth_logs

  config_elements:
    application_name: 'configuration_error_application_name'
    service_name: 'configuration-error_service_name'
    environment: {{ salt.grains.get('environment', 'configuration_error_environment') }}
    grafana_cloud_loki_endpoint: 'https://logs-prod-us-central1.grafana.net'
    grafana_cloud_prometheus_endpoint: 'https://prometheus-prod-10-prod-us-central-0.grafana.net/api/prom/push'
    grafana_cloud_loki_user: __vault__::secret-operations/global/grafana-cloud-credentials>data>loki_user
    grafana_cloud_cortex_user: __vault__::secret-operations/global/grafana-cloud-credentials>data>prometheus_user
    grafana_cloud_password: __vault__::secret-operations/global/grafana-cloud-credentials>data>api_key
