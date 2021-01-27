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
          category: ocw_build
    sinks:
      es_cluster:
        inputs:
          - enriched_webhook_publish_log
        type: elasticsearch
        host: 'http://operations-elasticsearch.query.consul:9200'
        index: logstash-ocw-build-%Y.%W
