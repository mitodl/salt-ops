{% set ENVIRONMENT = salt.grains.get('environment', 'dev') %}

vector:
  base_auth_log_collection:
    type: file
    file_key: log_file
    read_from: end
    include:
    - /var/log/auth.log
  base_auth_log_parse_source:
    type: remap
    inputs:
    - 'collect_auth_logs'
    source: |
      parsed, err = parse_syslog(.message)
      if err != null {
        .parse_error = err
      }
      . = merge(., parsed)
      .log_process = "authlog"
      .environment = "${ENVIRONMENT}"

  # These two are intentionally incomplete sink configurations. The type, inputs, and labels 
  #  need to be provided on a configuration-by-configuration basis.
  base_loki_configuration:
    auth:
      strategy: basic
      password: __vault__::secret-operations/global/grafana-cloud-credentials>data>api_key
      user: __vault__::secret-operations/global/grafana-cloud-credentials>data>loki_user
    endpoint: https://logs-prod-us-central1.grafana.net
    encoding:
      codec: json
    out_of_order_action: rewrite_timestamp
  base_cortex_configuration:
    endpoint: https://prometheus-prod-10-prod-us-central-0.grafana.net/api/prom/push
    healthcheck: false
    auth:
      strategy: basic
      user: __vault__::secret-operations/global/grafana-cloud-credentials>data>prometheus_user
      password: __vault__::secret-operations/global/grafana-cloud-credentials>data>api_key

  # By default, there are no extra vector configurations to add
  extra_configurations: []

  # Call out host metrics in their own area because they will be enabled globally
  host_metrics_configuration:
    sources:
      collect_host_metrics:
        type: host_metrics
        scrape_interval_secs: 60
        collectors:
          - cpu
          - filesystem
          - load
          - host
          - memory
          - network
    transforms:
      cleanup_host_metrics:
        type: remap
        inputs:
        - 'collect_host_metrics'
        source: |
          # Drop all the not-real filesystems metrics
          abort_match_filesystem, err = !(match_any(.tags.filesystem, [r'ext.', r'btrfs', r'xfs']))
          if abort_match_filesystem {
            abort
          }
      add_labels_to_host_metrics:
        type: remap
        inputs:
        - 'cleanup_host_metrics'
        source: |
          .tags.environment = "${ENVIRONMENT}"
          .tags.job = "integrations/linux_host"
    sinks:
      ship_host_metrics_to_grafana_cloud:
        inputs:
        - 'add_labels_to_host_metrics'
        {{ salt.pillar.get('vector:base_cortex_configuration')|yaml(False)|indent(8) }}
