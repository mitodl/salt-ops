{% set app_name = "fluentd-aggregators" %}
{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set minion_id = salt.grains.get('id', '') %}
{% set micromasters_ir_bucket = 'odl-micromasters-ir-data' %}
{% set micromasters_ir_bucket_creds = salt.vault.read('aws-mitx/creds/read-write-{bucket}'.format(bucket=micromasters_ir_bucket)) %}
{% set residential_tracking_bucket = 'odl-residential-tracking-data' %}
{% set xpro_tracking_bucket = 'odl-xpro-edx-tracking-data' %}
{% set data_lake_bucket = 'mitodl-data-lake' %}
{% set edx_tracking_bucket = 'odl-residential-tracking-data' %}
{% set edx_tracking_bucket_creds = salt.vault.read('aws-mitx/creds/read-write-{bucket}'.format(bucket=edx_tracking_bucket)) %}
{% set mailgun_webhooks_token = salt.vault.read('secret-operations/global/mailgun_webhooks_token').data.value %}
{% set redash_webhook_token = salt.vault.read('secret-operations/global/redash_webhook_token').data.value %}
{% set es_hosts = 'operations-elasticsearch.query.consul' %}
{% set cert = salt.vault.cached_write('pki-intermediate-operations/issue/fluentd-server', common_name='operations-fluentd.query.consul', cache_prefix=minion_id) %}
{% set fluentd_cert_path = salt.sdb.get('sdb://yaml/fluentd:cert_path') %}
{% set fluentd_cert_key_path = salt.sdb.get('sdb://yaml/fluentd:cert_key_path') %}
{% set ca_cert_path = salt.sdb.get('sdb://yaml/fluentd:ca_cert_path') %}
{% import_yaml 'fluentd/fluentd_directories.yml' as fluentd_directories %}

schedule:
  refresh_{{ app_name }}_configs:
    # Needed to ensure that S3 credentials remain valid
    days: 5
    function: state.sls
    args:
      - fluentd.config

# Default datadog-agent port conflicts with fluentd
datadog:
  config:
    expvar_port: 5004
    cmd_port: 5005

fluentd:
  persistent_directories: {{ fluentd_directories|tojson }}
  plugins:
    - fluent-plugin-heroku-syslog-http
    - fluent-plugin-s3
    - fluent-plugin-avro
    - fluent-plugin-anonymizer
    - fluent-plugin-elasticsearch
  proxied_plugins:
    - route: heroku-http
      port: 9000
      token: __vault__::secret-operations/global/heroku_http_token>data>value
    - route: mailgun-webhooks
      port: 9001
      token: __vault__::secret-operations/global/mailgun_webhooks_token>data>value
    - route: redash-webhook
      port: 9002
      token: __vault__::secret-operations/global/redash_webhook_token>data>value
  configs:
    monitor_agent:
      settings:
        - directive: source
          attrs:
            - '@type': monitor_agent
            - bind: 127.0.0.1
            - port: 24220
    fluentd_log:
      settings:
        - directive: label
          directive_arg: '@FLUENT_LOG'
          attrs:
            - nested_directives:
              - directive: filter
                attrs:
                  - '@type': record_transformer
                  - nested_directives:
                    - directive: record
                      attrs:
                        - host: "#{Socket.gethostname}"
              - directive: match
                directive_arg: 'fluent.*'
                attrs:
                  - '@id': fluentd_server_es_outbound
                  - '@type': elasticsearch_dynamic
                  - logstash_format: 'true'
                  - hosts: {{ es_hosts }}
                  - logstash_prefix: 'logstash-${record.fetch("environment", "blank") != "blank" ? record.fetch("environment") : tag_parts[0]}'
                  - include_tag_key: 'true'
                  - tag_key: fluentd_tag
                  - reload_on_failure: 'true'
                  - reconnect_on_error: 'true'
                  - flatten_hashes: 'true'
                  - flatten_hashes_separator: __
                  - nested_directives:
                      - directive: buffer
                        attrs:
                          - flush_interval: '10s'
                          - flush_thread_count: 2
    elasticsearch:
      settings:
        - directive: source
          attrs:
            - '@id': heroku_logs_inbound
            - '@type': heroku_syslog_http
            - tag: heroku_logs
            - bind: 9000
            - port: ::1
        - directive: source
          attrs:
            - '@id': mailgun-events
            - '@type': http
            - '@label': '@es_logging'
            - port: 9001
            - bind: ::1
            - nested_directives:
                - directive: parse
                  attrs:
                    - '@type': json
                    - keep_time_key: 'true'
        - directive: source
          attrs:
            - '@id': redash-events
            - '@type': http
            - port: 9002
            - bind: ::1
            - nested_directives:
                - directive: parse
                  attrs:
                    - '@type': json
                    - keep_time_key: 'true'
        - directive: source
          attrs:
            - '@id': salt_logs_inbound
            - '@type': udp
            - '@label': '@es_logging'
            - tag: saltmaster
            - port: 9999
            - bind: ::1
            - nested_directives:
                - directive: parse
                  attrs:
                    - '@type': json
                    - keep_time_key: 'true'
        - directive: source
          attrs:
            - '@type': forward
            - '@label': '@es_logging'
            - port: 5001
            - bind: '0.0.0.0'
            - nested_directives:
                - directive: transport
                  directive_arg: tls
                  attrs:
                    - cert_path: {{ fluentd_cert_path }}
                    - private_key_path: {{ fluentd_cert_key_path }}
                    - client_cert_auth: 'true'
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
                    - time_slice_format: '%Y-%m-%d-%H'
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
                  - hosts: {{ es_hosts }}
                  - logstash_prefix: 'logstash-${record.fetch("environment", "blank") != "blank" ? record.fetch("environment") : tag_parts[0]}'
                  - include_tag_key: 'true'
                  - tag_key: fluentd_tag
                  - reload_on_failure: 'true'
                  - reconnect_on_error: 'true'
                  - flatten_hashes: 'true'
                  - flatten_hashes_separator: __
                  - nested_directives:
                      - directive: buffer
                        attrs:
                          - flush_interval: '10s'
                          - flush_thread_count: 4

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
                    - time_slice_format: '%Y-%m-%d-%H'
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
                    - nested_directives:
                      - directive: regexp
                        attrs:
                          - key: environment
                          - pattern: mitxpro-production
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

beacons:
  service:
    - services:
        fluentd:
          onchangeonly: True
          delay: 60
          disable_during_state_run: True
    - interval: 60
