vector:
  extra_configurations:
  - name: rabbitmq_logs
    content:
      log_schema:
        timestamp_key: vector_timestamp
        host_key: log_host
      sources:
        collect_rabbitmq_application_logs:
          type: file
          read_from: end
          file_key: log_file
          glob_minimum_cooldown_ms: 20000
          include:
          - /var/log/rabbitmq/rabbit*.log
          multiline:
            start_pattern: r'^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+?) \[(\w+)\]'
            condition_pattern: r'^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+?) \[(\w+)\] (.*)$'
            mode: 'halt_before'
            timeout_ms: 5000
        collect_auth_logs:
        {{ salt.pillar.get('vector:base_auth_log_collection')|yaml(False)|indent(8) }}
      transforms:
        parse_rabbitmq_application_logs:
          type: remap
          inputs:
          - 'collect_rabbitmq_application_logs'
          source: |
            parsed, err = parse_regex(.message, r'^(?P<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+?) \[(?P<type>\w+)\] (?P<message>.*)$')
            if err != null {
              .parse_error = err
            }
            . = merge(., parsed)
            .log_process = "rabbitmq"
            .log_type = "rabbitmq.application"
            .environment = "${ENVIRONMENT}"

        parse_auth_logs:
          {{ salt.pillar.get('vector:base_auth_log_parse_source')|yaml(False)|indent(10) }}

      sinks:
        ship_rabbitmq_logs_to_grafana_cloud:
          inputs:
          - 'parse_rabbitmq_application_logs'
          - 'parse_auth_logs'
          labels:
            environment: ${ENVIRONMENT}
            application: rabbitmq
            service: rabbitmq
          type: loki
          {{ salt.pillar.get('vector:base_loki_configuration')|yaml(False)|indent(10) }}
