{% from "fluentd/record_tagging.jinja" import record_tagging with context %}
{% from "fluentd/auth_log.jinja" import auth_log_source, auth_log_filter with context %}

fluentd:
  plugins:
    - fluent-plugin-secure-forward
  configs:
    - name: auth_server
      settings:
        - directive: source
          attrs:
            - '@id': cas_nginx_access_log
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: cas.nginx.access
            - path: /var/log/nginx/access.log
            - pos_file: /var/log/nginx/access.log.pos
            - nested_directives:
                - directive: parse
                  attrs:
                    - '@type': ltsv
                    - null_value_pattern: '/^-$/'
                    - keep_time_key: 'true'
                    - label_delimiter: '='
                    - delimiter_pattern: '/\s+(?=(?:[^"]*"[^"]*")*[^"]*$)/'
                    - time_key: time
                    - types: time:time
        - directive: source
          attrs:
            - '@id': cas_nginx_error_log
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: cas.nginx.error
            - path: /var/log/nginx/error.log
            - pos_file: /var/log/nginx/error.log.pos
            - nested_directives:
                - directive: parse
                  attrs:
                    - '@type': regexp
                    - expression: '^(?<time>\d+\/\d+\/\d+\s\d+:\d+:\d+)\s(?<level_name>\[.*])\s(?<message>.*)'
        - directive: source
          attrs:
            - tag: cas.django
            - '@type': tail
            - enable_watch_timer: 'false'
            - path: /opt/log/django.log
            - pos_file: /opt/log/django.log.pos
            - format: multiline
            - format_firstline: '/^\[\d{4}-\d{2}-\d{2}\w+:\d{2}:\d{2}\]/'
            - format1: '/^\[(?<time>\d{4}-\d{2}-\d{2}\w+:\d{2}:\d{2})\] (?<log_level>\w+) \[(?<module_name>[a-zA-Z0-9-_.]+):(?<line_number>\d+)\] (?<message>.*)/'
            - time_format: '%d/%b/%Y %H:%M:%S'
            - multiline_flush_interval: '5s'
        - directive: filter
          directive_arg: '**'
          attrs:
            - '@type': grep
            - exclude1: agent Amazon Route 53 Health Check Service
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
                  - host: log-input.odl.mit.edu
                  - port: 5001
