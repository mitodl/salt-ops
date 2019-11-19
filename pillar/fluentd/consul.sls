{% from "fluentd/record_tagging.jinja" import record_tagging with context %}
{% from "fluentd/auth_log.jinja" import auth_log_source, auth_log_filter with context %}

fluentd:
  plugins:
    - fluent-plugin-secure-forward
  configs:
    - name: consul_server
      settings:
        - directive: source
          attrs:
            - '@type': tail
            - enable_watch_timer: 'false'
            - path: /var/log/syslog
            - pos_file: /var/log/syslog.pos
            - format: syslog
            - tag: consul.server
        - directive: filter
          directive_arg: '**'
          attrs:
            - '@type': grep
            - regexp1: ident consul
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
                  - host: operations-fluentd.query.consul
                  - port: 5001
