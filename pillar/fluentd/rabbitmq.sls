{% from "fluentd/record_tagging.jinja" import record_tagging with context %}
{% from "fluentd/auth_log.jinja" import auth_log_source, auth_log_filter with context %}
{% from "fluentd/tls_forward.jinja" import tls_forward with context %}
{% set host = salt.grains.get('host') %}

fluentd:
  configs:
    rabbitmq_server:
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
        - {{ tls_forward }}
