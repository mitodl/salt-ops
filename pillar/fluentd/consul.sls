{% from "fluentd/record_tagging.jinja" import record_tagging with context %}
{% from "fluentd/auth_log.jinja" import auth_log_source, auth_log_filter with context %}
{% from "fluentd/tls_forward.jinja" import tls_forward with context %}

fluentd:
  configs:
    consul_server:
      settings:
        - directive: source
          attrs:
            - '@type': tail
            - enable_watch_timer: 'false'
            - path: /var/log/syslog
            - pos_file: /var/log/syslog.pos
            - format: syslog
            - tag: consul.server
        - {{ auth_log_source('syslog.auth', '/var/log/auth.log') }}
        - {{ auth_log_filter('grep', 'ident', 'consul', 'consul.server', 'regexp') }}
        - {{ auth_log_filter('grep', 'ident', '/CRON/') }}
        - {{ record_tagging |yaml() }}
        - {{ tls_forward() }}
