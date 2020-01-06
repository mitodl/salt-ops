{% from "fluentd/record_tagging.jinja" import record_tagging with context %}
{% from "fluentd/auth_log.jinja" import auth_log_source, auth_log_filter with context %}
{% from "fluentd/tls_forward.jinja" import tls_forward with context %}

fluentd:
  overrides:
    pkgs:
      - ruby2.3
      - ruby2.3-dev
      - build-essential
  configs:
    - name: edx
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
                  - '@type': forward
                  - transport: tls
                  - tls_client_cert_path: {{ fluentd_cert_path }}
                  - tls_client_private_key_path: {{ fluentd_key_path }}
                  - tls_ca_cert_path: {{ ca_cert_path }}
                  - tls_allow_self_signed_cert: 'true'
                  - tls_verify_hostname: 'false'
                  - nested_directives:
                    - directive: server
                      attrs:
                        - host: operations-fluentd.query.consul
                        - port: 5001
        - directive: source
          attrs:
            - '@id': edx_nginx_access_log
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: edx.nginx.access
            - path: /edx/var/log/nginx/access.log
            - pos_file: /edx/var/log/nginx/access.log.pos
            - nested_directives:
                - directive: parse
                  attrs:
                    - '@type': ltsv
                    - keep_time_key: 'true'
                    - label_delimiter: '='
                    - delimiter_pattern: '/\s+(?=(?:[^"]*"[^"]*")*[^"]*$)/'
                    - time_key: time
                    - types: time:time
        - directive: source
          attrs:
            - '@id': edx_cms_log
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: edx.cms
            - path: /edx/var/log/cms/edx.log
            - pos_file: /edx/var/log/cms/edx.log.pos
            - format: multiline
            - format_firstline: '/^\w{3}\s+\d{1,2} \d{2}:\d{2}:\d{2}/'
            - format1: '/^(?<time>\w{3}\s+\d{1,2} \d{2}:\d{2}:\d{2}) (?<hostname>[^ ]+?) \[service_variant=(?<service_variant>\w+?)\]\[(?<namespace>[a-zA-Z._\-]+?)\]\[env:(?<logging_env>[a-zA-Z\-_.]+)\]\ (?<log_level>\w+) \[[^ ]+\s+\d+\] \[(?<filename>[a-zA-Z0-9\-_.]+):(?<line_number>\d+)\] - (?<message>.*)$/'
            - time_format: '%b %d %H:%M:%S'
            - multiline_flush_interval: '5s'
        - directive: source
          attrs:
            - '@id': edx_cms_stderr_log
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: edx.cms.stderr
            - path: /edx/var/log/supervisor/cms*-stderr.log
            - pos_file: /edx/var/log/supervisor/cms-stderr.pos
            - format: multiline
            - format_firstline: '/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/'
            - format1: '/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(?:,\d{3}| [+\-]\d{4}\])? (?<message>.*)/'
            - multiline_flush_interval: '5s'
        - directive: source
          attrs:
            - '@id': edx_lms_log
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: edx.lms
            - path: /edx/var/log/lms/edx.log
            - pos_file: /edx/var/log/lms/edx.log.pos
            - format: multiline
            - format_firstline: '/^\w{3}\s+\d{1,2} \d{2}:\d{2}:\d{2}/'
            - format1: '/^(?<time>\w{3}\s+\d{1,2} \d{2}:\d{2}:\d{2}) (?<hostname>[^ ]+?) \[service_variant=(?<service_variant>\w+?)\]\[(?<namespace>[a-zA-Z._\-]+?)\]\[env:(?<logging_env>[a-zA-Z\-_.]+)\]\ (?<log_level>\w+) \[[^ ]+\s+\d+\] \[(?<filename>[a-zA-Z0-9\-_.]+):(?<line_number>\d+)\] - (?<message>.*)$/'
            - time_format: '%b %d %H:%M:%S'
            - multiline_flush_interval: '5s'
        - directive: source
          attrs:
            - '@id': edx_lms_stderr_log
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: edx.lms.stderr
            - path: /edx/var/log/supervisor/lms*-stderr.log
            - pos_file: /edx/var/log/supervisor/lms-stderr.pos
            - format: multiline
            - format_firstline: '/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/'
            - format1: '/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(?:,\d{3}| [+\-]\d{4}\])? (?<message>.*)/'
            - multiline_flush_interval: '5s'
        - directive: source
          attrs:
            - '@id': edx_xqueue_log
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: edx.xqueue
            - path: /edx/var/log/xqueue/edx.log
            - pos_file: /edx/var/log/xqueue/edx.log.pos
            - format: multiline
            - format_firstline: '/^\w{3}\s+\d{1,2}\s+\d{1,2}:\d{2}:\d{2}/'
            - format1: '/^(?<time>\w{3}\s+\d{1,2}\s+\d{1,2}:\d{2}:\d{2}) (?<hostname>[^ ]+?) \[service_variant=(?<service_variant>\w+?)\]\[(?<namespace>[a-zA-Z._\-]+?)\]\[env:(?<logging_env>[a-zA-Z\-_.]+)\]\ (?<log_level>\w+) \[[^ ]+\s+\d+\] \[(?<filename>[a-zA-Z0-9\-_.]+):(?<line_number>\d+)\] - (?<message>.*)$/'
            - time_format: '%b %d %H:%M:%S'
            - multiline_flush_interval: '5s'
        {% if 'mitx-' in salt.grains.get('environment') %}
        - directive: source
          attrs:
            - '@id': edx_gitreload_log
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: edx.gitreload
            - path: /edx/var/log/gr/gitreload.log
            - pos_file: /edx/var/log/gr/gitreload.log.pos
            - format: multiline
            - format_firstline: '/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{0,3}?/'
            - format1: '/^(?<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}),\d{0,3}? (?<log_level>\w+?) (?<process_id>\d+) (?<logger_name>\[[\w._\d]+\]) (?<filename>[a-zA-Z0-9\-_.]+):(?<line_number>\d+) - (?<hostname>[^ ]+?)- (?<message>.*)/'
            - multiline_flush_interval: '5s'
        {% endif %}
        - directive: source
          attrs:
            - '@id': edx_tracking_log
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: edx.tracking
            - path: /edx/var/log/tracking/tracking.log
            - pos_file: /edx/var/log/tracking/tracking.log.pos
            - nested_directives:
                - directive: parse
                  attrs:
                    - '@type': json
                    - json_parser: json
                    - keep_time_key: 'true'
                    - time_type: string
                    - time_format: '%Y-%m-%dT%H:%M:%S.%N%:z'
        - {{ auth_log_source('syslog.auth', '/var/log/auth.log') }}
        - {{ auth_log_filter('grep', 'user_agent', '/ELB-HealthChecker/', 'edx.nginx.access') }}
        - {{ auth_log_filter('grep', 'message', '/heartbeat/', 'edx.lms.stderr') }}
        - {{ auth_log_filter('grep', 'ident', '/CRON/') }}
        - {{ record_tagging |yaml() }}
        - {{ tls_forward |yaml() }}
