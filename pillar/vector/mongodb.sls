vector:
  configuration:

    api:
      enabled: true

    log_schema:
      timestamp_key: "@timestamp"
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
        type: regex_parser
        drop_failed: true
        field: message
        overwrite_target: true
        patterns:
          - '^(?P<time>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}\+\d{4}) (?P<log_level>\w) (?P<component>\w+)\s+\[(?P<context>.+?)\] (?P<message>.*)'
        types:
          time: timestamp|%Y-%m-%dT%H:%M:%S%.3f%z

     field_adder:
        inputs:
          - log_parser
        type: add_fields
        fields:
          labels:
            - mongodb
          environment: {{ salt.grains.get('environment') }}

      timestamp_renamer:
        inputs:
          - field_adder
        type: rename_fields
        fields:
          time: "@timestamp"

    sinks:

      elasticsearch:
        inputs:
          - timestamp_renamer
        type: elasticsearch
        endpoint: 'http://operations-elasticsearch.query.consul:9200'
        index: logs-mongodb-%Y.%W
        healthcheck: false
