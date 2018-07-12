{% from "fluentd/record_tagging.jinja" import record_tagging with context %}
{% from "fluentd/auth_log.jinja" import auth_log_source, auth_log_filter with context %}
{% set host = salt.grains.get('host') %}

fluentd:
  plugins:
    - fluent-plugin-secure-forward
  configs:
    - name: rabbitmq_server
      settings:
        - directive: source
          attrs:
            - '@type': tail
            - tag: rabbitmq.server
            - enable_watch_timer: 'false'
            - path: /var/log/rabbitmq/rabbit@{{ host }}.log
            - pos_file: /var/log/rabbitmq/rabbit@{{ host }}.log.pos
            - format: multiline
            - format_firstline: '/^(?<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+?) \[(?<type>\w+)\]/'
            - format1: '/^(?<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+?) \[(?<type>\w+)\] (?<message>.*)$/'
            - multiline_flush_interval: '5s'
        - {{ auth_log_source('syslog.auth', '/var/log/auth.log') }}
        - {{ auth_log_filter('grep', 'ident', 'CRON') }}
        - {{ record_tagging |yaml() }}
        - directive: match
          directive_arg: '**'
          attrs:
            - '@type': secure_forward
            - self_hostname: {{ salt.grains.get('ipv4')[0] }}
            - secure: 'false'
            - flush_interval: '10s'
            - shared_key: __vault__::secret-operations/global/fluentd_shared_key>data>value
            - nested_directives:
              - directive: server
                attrs:
                  - host: fluentd.service.operations.consul
                  - port: 5001
