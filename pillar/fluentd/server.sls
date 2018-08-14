{% set micromasters_ir_bucket = 'odl-micromasters-ir-data' %}
{% set edx_tracking_bucket = 'odl-residential-tracking-data' %}
{% set data_lake_bucket = 'mitodl-data-lake' %}
{% import_yaml 'fluentd/fluentd_directories.yml' as fluentd_directories %}

schedule:
  regenerate_fluentd_config:
    # Needed to ensure that S3 credentials remain valid
    days: 25
    function: state.sls
    args:
      - fluentd.config

fluentd:
  persistent_directories: {{ fluentd_directories }}
  overrides:
    nginx_config:
      server_name: log-input.odl.mit.edu
      cert_file: log-input.crt
      key_file: log-input.key
      cert_contents: __vault__::secret-operations/global/odl_wildcard_cert>data>value
      key_contents: __vault__::secret-operations/global/odl_wildcard_cert>data>key
  plugins:
    - fluent-plugin-secure-forward
    - fluent-plugin-heroku-syslog
    - fluent-plugin-s3
    - fluent-plugin-avro
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
            - '@type': heroku_syslog_http
            - port: 9000
            - bind: ::1
            - format: 'none'
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
        - directive: source
          attrs:
            - '@type': secure_forward
            - port: 5001
            - secure: 'false'
            - cert_auto_generate: 'yes'
            - self_hostname: {{ salt.grains.get('external_ip') }}
            - shared_key: __vault__::secret-operations/global/fluentd_shared_key>data>value
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
                    - buffer_path: {{ fluentd_directories.micromasters_s3_buffers }}
                    - format: json
                    - include_time_key: 'true'
                    - time_slice_format: '%Y-%m-%d'
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
                  - '@label': '@prod_edx_tracking_events'
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
            # - nested_directives:
            #     - directive: buffer
            #       attrs:
            #         - '@type': file
            #         - path: {{ fluentd_directories.universal_buffer }}
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
                  - hosts: elasticsearch.service.operations.consul
                  - logstash_prefix: 'logstash-${record.fetch("environment", "blank") != "blank" ? record.fetch("environment") : tag_parts[0]}'
                  - include_tag_key: 'true'
                  - tag_key: fluentd_tag
                  - reload_on_failure: 'true'
                  - reconnect_on_error: 'true'
                  - flatten_hashes: 'true'
                  - flatten_hashes_separator: __

        - directive: label
          directive_arg: '@prod_edx_tracking_events'
          attrs:
            - nested_directives:
                - directive: filter
                  directive_arg: 'edx.tracking'
                  attrs:
                    - '@type': grep
                    - regexp1: environment mitx-production
                - directive: match
                  directive_arg: edx.tracking
                  attrs:
                    - '@type': s3
                    - aws_key_id: __vault__:cache:aws-mitx/creds/read-write-{{ edx_tracking_bucket }}>data>access_key
                    - aws_sec_key: __vault__:cache:aws-mitx/creds/read-write-{{ edx_tracking_bucket }}>data>secret_key
                    - s3_bucket: {{ edx_tracking_bucket }}
                    - s3_region: us-east-1
                    - path: logs/
                    - buffer_path: {{ fluentd_directories.residential_tracking_logs }}
                    - format: json
                    - include_time_key: 'true'
                    - time_slice_format: '%Y-%m-%d-%H'
        - directive: label
          directive_arg: '@mailgun_s3_data_lake'
          attrs:
            - nested_directives:
                - directive: match
                  directive_arg: mailgun.**
                  attrs:
                    - '@type': s3
                    - aws_key_id: __vault__:cache:aws-mitx/creds/read-write-{{ data_lake_bucket }}>data>access_key
                    - aws_sec_key: __vault__:cache:aws-mitx/creds/read-write-{{ data_lake_bucket }}>data>secret_key
                    - s3_bucket: {{ data_lake_bucket }}
                    - s3_region: us-east-1
                    - path: mailgun/${tag[3]}/
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
    fluentd:
      onchangeonly: True
    disable_during_state_run: True
