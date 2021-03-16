vector:
  configuration:

    api:
      enabled: true

    log_schema:
      timestamp_key: vector_timestamp
      host_key: log_host

    sources:

      mongodb_log:
        type: file
        file_key: log_file
        include:
          - /var/log/mongodb/mongodb.log

    transforms:

      log_parser:
        inputs:
          - mongodb_log
        type: remap
        source: |
          matches, err = parse_regex(
            .message,
            r'^(?P<time>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}\+\d{4}) (?P<log_level>\w) (?P<component>\w+)\s+\[(?P<context>.+?)\] (?P<message>.*)'
          )
          if matches != null {
            @timestamp = parse_timestamp!(matches.time, "%FT%T%.3f%z")
            .message = matches.message
            .component = matches.component
            .context = matches.context
            .labels = ["mongodb"]
            .environment = "{{ salt.grains.get('environment') }}"
          } else {
            log(err, level: "error")
            .malformed = true
          }

      malformed_message_filter:
        inputs:
          - log_parser
        type: filter
        condition: .malformed != true

    sinks:

      elasticsearch:
        inputs:
          - malformed_message_filter
        type: elasticsearch
        endpoint: 'http://operations-elasticsearch.query.consul:9200'
        index: logs-mongodb-%Y.%W
        healthcheck: false
