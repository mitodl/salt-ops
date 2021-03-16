vector:
  configuration:
    api:
      enabled: true

    log_schema:
      timestamp_key: vector_timestamp
      host_key: log_host

    sources:
      webhook_publish_log:
        type: file
        include:
          - /opt/ocw/logs/webhook-publish.log

    transforms:
      webhook_publish_log_parser:
        inputs:
          - webhook_publish_log
        type: remap
        source: |
          matches, err = parse_regex(
            .message,
            r'^(?P<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{9}) (?P<message>.*)'
          )
          if matches != null {
            .message = matches.message
            .@timestamp = parse_timestamp!(matches.time, "%F %T%.9f")
            .labels = ["ocw_build"]
            .environment = "{{ salt.grains.get('environment') }}"
          } else {
            log(err, level: "error")
            .malformed = true
          }
      webhook_publish_malformed_message_filter:
        inputs:
          - webhook_publish_log_parser
        type: filter
        condition: .malformed != true

    sinks:
      es_cluster:
        inputs:
          - webhook_publish_malformed_message_filter
        type: elasticsearch
        endpoint: 'http://operations-elasticsearch.query.consul:9200'
        index: logstash-ocw-build-%Y.%W
        healthcheck: false
