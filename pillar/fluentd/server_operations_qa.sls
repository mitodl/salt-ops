{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set mailgun_webhooks_token = salt.vault.read('secret-operations/{}/mailgun_webhooks_token'.format(ENVIRONMENT)).data.value %}
{% set es_hosts = 'operations-elasticsearch.query.consul' %}
{% set cert = salt.vault.cached_write('pki-intermediate-operations/issue/fluentd-server', common_name='{}'.format(es_hosts)) %}

fluentd:
  overrides:
    nginx_config:
      server_name: logs-qa.odl.mit.edu
      cert_file: log-input.crt
      key_file: log-input.key
      cert_contents: __vault__::secret-operations/global/odl_wildcard_cert>data>value
      key_contents: __vault__::secret-operations/global/odl_wildcard_cert>data>key
  cert:
    - fluentd_cert: {{ cert.data.certificate }}
    - fluentd_key: {{ cert.data.private_key }}
    - ca_cert: {{ cert.data.issuing_ca }}
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
            - tag: heroku_logs
            - port: 9000
            - bind: ::1
        - directive: source
          attrs:
            - '@id': mailgun-events
            - '@type': http
            - port: 9001
            - bind: ::1
        - directive: source
          attrs:
            - '@id': salt_logs_inbound
            - '@type': udp
            - tag: saltmaster
            - format: json
            - port: 9999
            - bind: ::1
            - nested_directives:
                - directive: parse
                  attrs:
                    - keep_time_key: 'true'
        - directive: source
          attrs:
            - '@type': forward
            - port: 5001
            - bind: ::1
            - nested_directives:
                - directive: security
                  attrs:
                    - self_hostname: {{ salt.grains.get('external_ip') }}
                - directive: transport
                  directive_arg: tls
                  attrs:
                    - cert_path: /etc/fluent/fluentd.crt
                    - private_key_path: /etc/fluent/fluentd.key
                    - ca_path: /etc/fluent/ca.crt
                    - client_cert_auth: 'true'
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
                  - '@type': elasticsearch
                  - scheme: https
                  - logstash_format: 'true'
                  - flush_interval: '10s'
                  - hosts: {{ es_hosts }}
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
