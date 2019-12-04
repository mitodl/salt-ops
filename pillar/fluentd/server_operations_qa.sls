{% set app_name = "fluentd-aggregators" %}
{% set fluentd_shared_key = salt.vault.read('secret-operations/operations-qa/fluentd_shared_key').data.value %}
{% set heroku_http_token = salt.vault.read('secret-operations/operations-qa/heroku_http_token').data.value %}
{% set mailgun_webhooks_token = salt.vault.read('secret-operations/operations-qa/mailgun_webhooks_token').data.value %}
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
  plugins:
    - fluent-plugin-heroku-syslog
    - fluent-plugin-s3
    - fluent-plugin-elasticsearch
  proxied_plugins:
    - route: heroku-http
      port: 9000
      token: {{ heroku_http_token }}
    - route: mailgun-webhooks
      port: 9001
      token: {{ mailgun_webhooks_token }}
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
            - bind: ::1
            - port: 9000
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
            - '@id': salt_logs_inbound
            - '@type': udp
            - tag: saltmaster
            - format: json
            - port: 9999
            - keep_time_key: 'true'
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

beacons:
  service:
    - services:
        fluentd:
          onchangeonly: True
          delay: 60
          disable_during_state_run: True
    - interval: 60
