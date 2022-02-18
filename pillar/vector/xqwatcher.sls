vector:
  extra_configurations:
  - name: xqueuewatcher_logs
    content:
      log_schema:
        timestamp_key: vector_timestamp
        host_key: log_host
      sources:
        collect_xqwatcher_application_logs:
          type: file
          read_from: end
          file_key: log_file
          glob_minimum_cooldown_ms: 20000
          include:
          - /edx/var/log/xqwatcher/xqwatcher.log
          multiline:
            start_pattern: r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d+'
            condition_pattern: r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d+'
            mode: halt_before
            timeout_ms: 5000
        collect_xqwatcher_stderr_logs:
          type: file
          read_from: end
          file_key: log_file
          glob_minimum_cooldown_ms: 20000
          include:
          - /edx/var/log/supervisor/xqwatcher-stderr.log
          multiline:
            start_pattern: r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d+'
            condition_pattern: r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d+'
            mode: halt_before
            timeout_ms: 5000
        collect_xqwatcher_supervisord_logs:
          type: file
          read_from: end
          file_key: log_file
          glob_minimum_cooldown_ms: 20000
          include:
          - /edx/var/log/supervisor/supervisord.log
          multiline:
            start_pattern: r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d+'
            condition_pattern: r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d+'
            mode: halt_before
            timeout_ms: 5000
        collect_auth_logs:
        {{ salt.pillar.get('vector:base_auth_log_collection')|yaml(False)|indent(8) }}
      transforms:
        parse_xqwatcher_application_logs:
          type: remap
          inputs:
          - 'collect_xqwatcher_application_logs'
          source: |
            parsed, err = parse_regex(.message, r'^(?P<time>^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d+)\s-\s(?P<file_name>.*):(?P<line_number>\d+)\s--\s(?P<function_name>\w+)\s\[(?P<log_level>\w+)\]:\s(?P<message>.*)')
            if err != null {
              .parse_error = err
            }
            . = merge(., parsed)
            .log_process = "xqwatcher"
            .log_type = "xqwatcher.application"
            .environment = "${ENVIRONMENT}"
        filter_debug_xqwatcher_application_logs:
          inputs:
          - 'parse_xqwatcher_application_logs'
          type: filter
          condition: .log_level != "DEBUG"
        parse_xqwatcher_stderr_logs:
          type: remap
          inputs:
          - 'collect_xqwatcher_stderr_logs'
          source: |
            parsed, err = parse_regex(.message, r'^(?P<time>^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d+)\s-\s(?P<file_name>.*):(?P<line_number>\d+)\s--\s(?P<function_name>\w+)\s\[(?P<log_level>\w+)\]:\s(?P<message>.*)')
            if err != null {
              .parse_error = err
            }
            . = merge(., parsed)
            .log_process = "xqwatcher"
            .log_type = "xqwatcher.stderr"
            .environment = "${ENVIRONMENT}"
        filter_debug_xqwatcher_stderr_logs:
          inputs:
          - 'parse_xqwatcher_stderr_logs'
          type: filter
          condition: .log_level != "DEBUG"
        parse_xqwatcher_supervisord_logs:
          type: remap
          inputs:
          - 'collect_xqwatcher_supervisord_logs'
          source: |
            parsed, err = parse_regex(.message, r'^(?P<time>^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d+)\s(?P<log_level>\w+)\s(?P<message>.*)')
            if err != null {
              .parse_error = err
            }
            . = merge(., parsed)
            .log_process = "xqwatcher"
            .log_type = "xqwatcher.supervisord"
            .environment = "${ENVIRONMENT}"
        filter_debug_xqwatcher_supervisord_logs:
          inputs:
          - 'parse_xqwatcher_supervisord_logs'
          type: filter
          condition: .log_level != "DEBUG"
        parse_auth_logs:
          {{ salt.pillar.get('vector:base_auth_log_parse_source')|yaml(False)|indent(10) }}
      sinks:
        ship_xqwatcher_logs_to_grafana_cloud:
          type: loki
          inputs:
          - 'filter_debug_xqwatcher_application_logs'
          - 'filter_debug_xqwatcher_stderr_logs'
          - 'filter_debug_xqwatcher_supervisord_logs'
          - 'parse_auth_logs'
          labels:
            environment: ${ENVIRONMENT}
            applicaiton: xqwatcher
            service: xqwatcher
