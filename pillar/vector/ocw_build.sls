{% set ENVIRONMENT = salt.grains.get('environment') %}

vector:
  configuration:
    api:
      enabled: true
    sources:
      webhook_publish_log:
        type: file
        include:
          - /opt/ocw/logs/webhook-publish.log
    transforms:
      webhook_publish_log_parser:
        inputs:
          - webhook_publish_log
        type: regex_parser
        field: message
        patterns:
          - '^(?P<timestamp>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{9}) (?P<message>.*)$'
        types:
          timestamp: timestamp|%Y-%m-%d %H:%M:%S.%f
        overwrite_target: true
      enriched_webhook_publish_log:
        inputs:
          - webhook_publish_log_parser
        type: add_fields
        fields:
          environment: {{ ENVIRONMENT }}
          roles:
            - ocw-build
          labels:
            - ocwbuild.webhook-publish
    sinks:
      aggregator:
        type: vector
        inputs:
          - enriched_webhook_publish_log
        address: CHANGE THIS to equivalnt of log-input-qa.odl.mit.edu
        healthcheck: true
