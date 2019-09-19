{% from "fluentd/record_tagging.jinja" import record_tagging with context %}
{% from "fluentd/auth_log.jinja" import auth_log_source, auth_log_filter with context %}

fluentd:
  overrides:
    pkgs:
      - ruby2.3
      - ruby2.3-dev
      - build-essential
  plugins:
    - fluent-plugin-secure-forward
  configs:
    - name: edx
      settings:
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
            - format1: '/^(?<time>\w{3}\s+\d{1,2} \d{2}:\d{2}:\d{2}) (?<hostname>[^ ]+?) \[service_variant=(?<service_variant>\w+?)\]\[(?<namespace>[a-zA-Z._-]+?)\]\[env:(?<logging_env>[a-zA-Z-_.]+)\]\ (?<log_level>\w+) \[[^ ]+\s+\d+\] \[(?<filename>[a-zA-Z0-9-_.]+):(?<line_number>\d+)\] - (?<message>.*)$/'
            - time_format: '%b %d %H:%M:%S'
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
            - format1: '/^(?<time>\w{3}\s+\d{1,2} \d{2}:\d{2}:\d{2}) (?<hostname>[^ ]+?) \[service_variant=(?<service_variant>\w+?)\]\[(?<namespace>[a-zA-Z._-]+?)\]\[env:(?<logging_env>[a-zA-Z-_.]+)\]\ (?<log_level>\w+) \[[^ ]+\s+\d+\] \[(?<filename>[a-zA-Z0-9-_.]+):(?<line_number>\d+)\] - (?<message>.*)$/'
            - time_format: '%b %d %H:%M:%S'
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
            - format1: '/^(?<time>\w{3}\s+\d{1,2}\s+\d{1,2}:\d{2}:\d{2}) (?<hostname>[^ ]+?) \[service_variant=(?<service_variant>\w+?)\]\[(?<namespace>[a-zA-Z._-]+?)\]\[env:(?<logging_env>[a-zA-Z-_.]+)\]\ (?<log_level>\w+) \[[^ ]+\s+\d+\] \[(?<filename>[a-zA-Z0-9-_.]+):(?<line_number>\d+)\] - (?<message>.*)$/'
            - time_format: '%b %d %H:%M:%S'
            - multiline_flush_interval: '5s'
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
            - format1: '/^(?<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}),\d{0,3}? (?<log_level>\w+?) (?<process_id>\d+) (?<logger_name>\[[\w._\d]+\]) (?<filename>[a-zA-Z0-9-_.]+):(?<line_number>\d+) - (?<hostname>[^ ]+?)- (?<message>.*)/'
            - multiline_flush_interval: '5s'
        - directive: source
          attrs:
            - '@id': edx_tracking_log
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: edx.tracking
            - path: /edx/var/log/tracking/tracking.log
            - pos_file: /edx/var/log/tracking/tracking.log.pos
            - format: json
            - time_format: '%Y-%m-%dT%H:%M:%S.%N+%z'
        - {{ auth_log_source('syslog.auth', '/var/log/auth.log') }}
        - {{ auth_log_filter('grep', 'ident', 'python') }}
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
