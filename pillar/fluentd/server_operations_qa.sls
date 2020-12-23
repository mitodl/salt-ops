{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set minion_id = salt.grains.get('id', '') %}
{% set mailgun_webhooks_token = salt.vault.read('secret-operations/{}/mailgun_webhooks_token'.format(ENVIRONMENT)).data.value %}
{% set es_hosts = 'operations-elasticsearch.query.consul' %}
{% set cert = salt.vault.cached_write('pki-intermediate-operations/issue/fluentd-server', common_name='operations-fluentd.query.consul', cache_prefix=minion_id) %}
{% set fluentd_cert_path = '/etc/fluent/fluentd.crt' %}
{% set fluentd_key_path = '/etc/fluent/fluentd.key' %}
{% set ca_cert_path = '/etc/fluent/ca.crt' %}

fluentd:
  overrides:
    nginx_config:
      server_name: logs-qa.odl.mit.edu
      cert_file: log-input.crt
      key_file: log-input.key
      cert_contents: __vault__::secret-operations/global/odl_wildcard_cert>data>value
      key_contents: __vault__::secret-operations/global/odl_wildcard_cert>data>key
  cert:
    fluentd_cert:
      content: |
        {{ cert.data.certificate|indent(8)}}
      path: {{ fluentd_cert_path }}
    fluentd_key:
      content: |
        {{ cert.data.private_key|indent(8) }}
      path: {{ fluentd_key_path }}
    ca_cert:
      content: |
        {{ cert.data.issuing_ca|indent(8) }}
      path: {{ ca_cert_path }}
  plugins:
    - fluent-plugin-heroku-syslog-http
    - fluent-plugin-elasticsearch
  proxied_plugins:
    - route: heroku-http
      port: 9000
      token: __vault__::secret-operations/{{ ENVIRONMENT }}/heroku_http_token>data>value
    - route: mailgun-webhooks
      port: 9001
      token: __vault__::secret-operations/{{ ENVIRONMENT }}/mailgun_webhooks_token>data>value
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
                  - logstash_dateformat: '%Y.%W'
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
            - '@label': '@es_logging'
            - tag: heroku_logs
            - port: 9000
            - bind: ::1
        - directive: source
          attrs:
            - '@id': mailgun-events
            - '@type': http
            - '@label': '@es_logging'
            - port: 9001
            - bind: ::1
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
                    - private_key_path: {{ fluentd_key_path }}
                    - client_cert_auth: 'false'
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
                  - logstash_dateformat: '%Y.%W'
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

beacons:
  service:
    - services:
        fluentd:
          onchangeonly: True
          delay: 60
          disable_during_state_run: True
    - interval: 60
