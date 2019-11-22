{% set app_name = "fluentd-aggregators" %}
{% set micromasters_ir_bucket = 'odl-micromasters-ir-data' %}
{% set micromasters_ir_bucket_creds = salt.vault.read('aws-mitx/creds/read-write-{bucket}'.format(bucket=micromasters_ir_bucket)) %}
{% set residential_tracking_bucket = 'odl-residential-tracking-data' %}
{% set xpro_tracking_bucket = 'odl-xpro-edx-tracking-data' %}
{% set data_lake_bucket = 'mitodl-data-lake' %}
{% set edx_tracking_bucket = 'odl-residential-tracking-data' %}
{% set edx_tracking_bucket_creds = salt.vault.read('aws-mitx/creds/read-write-{bucket}'.format(bucket=edx_tracking_bucket)) %}
{% set fluentd_shared_key = salt.vault.read('secret-operations/global/fluentd_shared_key').data.value %}
{% set mailgun_webhooks_token = salt.vault.read('secret-operations/global/mailgun_webhooks_token').data.value %}
{% set redash_webhook_token = salt.vault.read('secret-operations/global/redash_webhook_token').data.value %}
{% set odl_wildcard_cert = salt.vault.read('secret-operations/global/odl_wildcard_cert') %}
{% import_yaml 'fluentd/fluentd_directories.yml' as fluentd_directories %}

schedule:
  refresh_{{ app_name }}_configs:
    # Needed to ensure that S3 credentials remain valid
    days: 5
    function: state.sls
    args:
      - fluentd.config

fluentd:
  persistent_directories: {{ fluentd_directories|tojson }}
  overrides:
    nginx_config:
      server_name: log-input.odl.mit.edu
      cert_file: log-input.crt
      key_file: log-input.key
      cert_contents: __vault__::secret-operations/global/odl_wildcard_cert>data>value
      key_contents: __vault__::secret-operations/global/odl_wildcard_cert>data>key
  plugins:
    - fluent-plugin-s3
    - fluent-plugin-avro
    - fluent-plugin-anonymizer
    - fluent-plugin-logzio
    - fluent-plugin-elasticsearch
  proxied_plugins:
    - route: mailgun-webhooks
      port: 9001
      token: __vault__::secret-operations/global/mailgun_webhooks_token>data>value
    - route: redash-webhook
      port: 9002
      token: __vault__::secret-operations/global/redash_webhook_token>data>value
  configs:
    - name: monitor_agent
      settings:
        - directive: source
          attrs:
            - '@type': monitor_agent
            - bind: 127.0.0.1
            - port: 24220
    - name: elasticsearch
      settings:
        - directive: source
          attrs:
            - '@id': heroku_logs_inbound
            - '@type': syslog
            - tag: heroku_logs
            - bind: 127.0.0.1
            - port: 5140
            - protocol_type: tcp
            - nested_directives:
                - directive: parse
                  attrs:
                    - message_format: rfc5424
        - directive: source
          attrs:
            - '@id': mailgun-events
            - '@type': http
            - port: 9001
            - bind: ::1
            - format: json
        - directive: source
          attrs:
            - '@id': redash-events
            - '@type': http
            - port: 9002
            - bind: ::1
            - format: json
        - directive: source
          attrs:
            - '@id': salt_logs_inbound
            - '@type': udp
            - tag: saltmaster
            - format: json
            - port: 9999
            - keep_time_key: 'true'
        - directive: filter
          directive_arg: 'mailgun.**'
          attrs:
            - '@type': anonymizer
            - nested_directives:
                - directive: mask
                  directive_arg: sha256
                  attrs:
                    - value_pattern: '^[a-zA-Z0-9_.+\-]+@[a-zA-Z0-9\-]+\.[a-zA-Z0-9\-.]+$'
                    - salt: __vault__:gen_if_missing:secret-operations/global/anonymizer-hash-salt>data>value
                - directive: mask
                  directive_arg: sha256
                  attrs:
                    - salt: __vault__:gen_if_missing:secret-operations/global/anonymizer-hash-salt>data>value
                    - keys: $["event-data"]["envelope"]["targets"], $["event-data"]["message"]["headers"]["to"], $["event-data"]["message"]["recipients"], $["event-data"]["recipient"]
                    - mask_array_elements: 'true'
                - directive: mask
                  directive_arg: network
                  attrs:
                    - keys: $["event-data"]["ip"]
                    - ipv4_mask_bits: 24
                    - ipv6_mask_bits: 104
        - directive: source
          attrs:
            - '@id': secure_input
            - '@type': forward
            - port: 5001
            - nested_directives:
              - directive: transport
                directive_arg: tls
                attrs:
                  - cert_path: '/etc/ssl/certs/log-input.crt'
                  - private_key_path: '/etc/ssl/certs/log-input.key'
                  - private_key_passphrase: ''
        {# The purpose of this block is to stream data from the
        micromasters application to S3 for analysis by the
        institutional research team. If they ever need to change
        the way that they consume that data then this is the
        place to change it. #}
        - directive: match
          directive_arg: heroku.micromasters
          attrs:
            - '@type': copy
            - nested_directives:
                - directive: store
                  attrs:
                    - '@type': s3
                    - aws_key_id: __vault__:cache:aws-mitx/creds/read-write-{{ micromasters_ir_bucket }}>data>access_key
                    - aws_sec_key: __vault__:cache:aws-mitx/creds/read-write-{{ micromasters_ir_bucket }}>data>secret_key
                    - s3_bucket: {{ micromasters_ir_bucket }}
                    - s3_region: us-east-1
                    - path: logs/
                    - s3_object_key_format: '%{path}%{time_slice}_%{index}.%{file_extension}'
                    - time_slice_format: '%Y-%m-%d'
                    - nested_directives:
                      - directive: buffer
                        attrs:
                          - '@type': file
                          - path: {{ fluentd_directories.micromasters_s3_buffers }}
                          - timekey: 3600
                          - timekey_wait: '10m'
                          - timekey_use_utc: 'true'
                    - nested_directives:
                      - directive: format
                        attrs:
                          - '@type': json
                - directive: store
                  attrs:
                    - '@type': relabel
                    - '@label': '@es_logging'
        {# End IR block #}
        - directive: match
          directive_arg: edx.tracking
          attrs:
            - '@type': copy
            - nested_directives:
              - directive: store
                attrs:
                  - '@type': relabel
                  - '@label': '@prod_residential_tracking_events'
              - directive: store
                attrs:
                  - '@type': relabel
                  - '@label': '@prod_xpro_tracking_events'
              - directive: store
                attrs:
                  - '@type': relabel
                  - '@label': '@es_logging'
        - directive: match
          directive_arg: mailgun.**
          attrs:
            - '@type': copy
            - nested_directives:
              - directive: store
                attrs:
                  - '@type': relabel
                  - '@label': '@mailgun_s3_data_lake'
              - directive: store
                attrs:
                  - '@type': relabel
                  - '@label': '@es_logging'
        - directive: match
          directive_arg: 'edx.xqwatcher.686.**'
          attrs:
            - '@type': copy
            - nested_directives:
              - directive: store
                attrs:
                  - '@type': relabel
                  - '@label': '@logzio_686'
              - directive: store
                attrs:
                  - '@type': relabel
                  - '@label': '@es_logging'
        - directive: match
          directive_arg: '**'
          attrs:
            - '@type': relabel
            - '@label': '@es_logging'
        - directive: label
          directive_arg: '@es_logging'
          attrs:
            - nested_directives:
              - directive: match
                directive_arg: '**'
                attrs:
                  - '@id': es_outbound
                  - '@type': elasticsearch_dynamic
                  - logstash_format: 'true'
                  - flush_interval: '10s'
                  - hosts: operations-elasticsearch.query.consul
                  - logstash_prefix: 'logstash-${record.fetch("environment", "blank") != "blank" ? record.fetch("environment") : tag_parts[0]}'
                  - include_tag_key: 'true'
                  - tag_key: fluentd_tag
                  - reload_on_failure: 'true'
                  - reconnect_on_error: 'true'
                  - flatten_hashes: 'true'
                  - flatten_hashes_separator: __

        - directive: label
          directive_arg: '@prod_residential_tracking_events'
          attrs:
            - nested_directives:
                - directive: filter
                  directive_arg: 'edx.tracking'
                  attrs:
                    - '@type': grep
                    - nested_directives:
                      - directive: regexp
                        attrs:
                          - key: environment
                          - pattern: mitx-production
                - directive: match
                  directive_arg: edx.tracking
                  attrs:
                    - '@type': s3
                    - aws_key_id: __vault__:cache:aws-mitx/creds/read-write-{{ residential_tracking_bucket }}>data>access_key
                    - aws_sec_key: __vault__:cache:aws-mitx/creds/read-write-{{ residential_tracking_bucket }}>data>secret_key
                    - s3_bucket: {{ residential_tracking_bucket }}
                    - s3_region: us-east-1
                    - path: logs/
                    - s3_object_key_format: '%{path}%{time_slice}_%{index}.%{file_extension}'
                    - time_slice_format: '%Y-%m-%d'
                    - nested_directives:
                      - directive: buffer
                        attrs:
                          - '@type': file
                          - path: {{ fluentd_directories.residential_tracking_logs }}
                          - timekey: 3600
                          - timekey_wait: '10m'
                          - timekey_use_utc: 'true'
                    - nested_directives:
                      - directive: format
                        attrs:
                          - '@type': json
        - directive: label
          directive_arg: '@prod_xpro_tracking_events'
          attrs:
            - nested_directives:
                - directive: filter
                  directive_arg: 'edx.tracking'
                  attrs:
                    - '@type': grep
                    - regexp1: environment mitxpro-production
                - directive: match
                  directive_arg: edx.tracking
                  attrs:
                    - '@type': s3
                    - aws_key_id: __vault__:cache:aws-mitx/creds/read-write-{{ xpro_tracking_bucket }}>data>access_key
                    - aws_sec_key: __vault__:cache:aws-mitx/creds/read-write-{{ xpro_tracking_bucket }}>data>secret_key
                    - s3_bucket: {{ xpro_tracking_bucket }}
                    - s3_region: us-east-1
                    - path: logs/
                    - s3_object_key_format: '%{path}%{time_slice}_%{index}.%{file_extension}'
                    - time_slice_format: '%Y-%m-%d'
                    - nested_directives:
                      - directive: buffer
                        attrs:
                          - '@type': file
                          - path: {{ fluentd_directories.xpro_tracking_logs }}
                          - timekey: 3600
                          - timekey_wait: '10m'
                          - timekey_use_utc: 'true'
                    - nested_directives:
                      - directive: format
                        attrs:
                          - '@type': json
        - directive: label
          directive_arg: '@mailgun_s3_data_lake'
          attrs:
            - nested_directives:
                - directive: filter
                  directive_arg: 'mailgun.**'
                  attrs:
                    - '@type': record_transformer
                    - enable_ruby: 'true'
                    - remove_keys: event-data
                    - nested_directives:
                        - directive: record
                          attrs:
                            - event_data: ${JSON.load(record["event-data"].to_json.gsub(/[{,]"\w+-\w+?-?\w+":/){|m| m.gsub("-", "_")})}
                - directive: match
                  directive_arg: mailgun.**
                  attrs:
                    - '@type': s3
                    - aws_key_id: __vault__:cache:aws-mitx/creds/read-write-{{ data_lake_bucket }}>data>access_key
                    - aws_sec_key: __vault__:cache:aws-mitx/creds/read-write-{{ data_lake_bucket }}>data>secret_key
                    - s3_bucket: {{ data_lake_bucket }}
                    - s3_region: us-east-1
                    - path: mailgun/${tag}/
                    - nested_directives:
                        - directive: buffer
                          directive_arg: tag,time
                          attrs:
                            - '@type': file
                            - path: {{ fluentd_directories.data_lake }}mailgun
                            - timekey: 3600 # 12 hours
                        - directive: format
                          attrs:
                            - '@type': json
                    - include_time_key: 'true'
                    - time_slice_format: '%Y-%m-%d-%H'
        - directive: label
          directive_arg: '@logzio_686'
          attrs:
            - nested_directives:
                - directive: match
                  directive_arg: 'edx.xqwatcher.686.**'
                  attrs:
                    - '@type': logzio_buffered
                    - endpoint_url: __vault__::secret-residential/mitx-production/logzio-686-url>data>value
                    - output_include_time: 'true'
                    - output_include_tags: 'true'
                    - http_idle_timeout: 10
                    - nested_directives:
                        - directive: buffer
                          attrs:
                            - '@type': memory
                            - flush_thread_count: 4
                            - flush_interval: '3s'
                            - chunk_limit_size: 16m
                            - queue_limit_length: 4096

beacons:
  service:
    - services:
        fluentd:
          onchangeonly: True
          delay: 60
          disable_during_state_run: True
    - interval: 60
