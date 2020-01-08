{% from "fluentd/record_tagging.jinja" import record_tagging with context %}
{% from "fluentd/auth_log.jinja" import auth_log_source, auth_log_filter with context %}
{% from "fluentd/tls_forward.jinja" import tls_forward with context %}

fluentd:
  configs:
    reddit:
      settings:
        - directive: source
          attrs:
            - '@id': reddit_mcrouter_log
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: reddit.mcrouter
            - path: /var/log/mcrouter/mcrouter.log
            - pos_file: /var/log/mcrouter/mcrouter.log.pos
            - nested_directives:
                - directive: parse
                  attrs:
                    - '@type': regexp
                    - expression: '^(?<time>\w\d{4}\s\d{2}:\d{2}:\d{2}.\d{6})\s*(?<code_value>\d+)\s*(?<file_name>.*):(?<line_num>\d+)\]\s*(?<message>.*)$'
        - directive: source
          attrs:
            - '@id': reddit_log
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: reddit.paster
            - path: /var/log/reddit/reddit.log
            - pos_file: /var/log/reddit/reddit.log.pos
            - nested_directives:
                - directive: parse
                  attrs:
                    - '@type': regexp
                    - expression: '^(?<asctime>\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2},\d{3})\s-(?<file_name>.*)(?<line_num>\d+)\s--\s(?<func_name>\w+)\s(?<level_name>\[\w+\]):(?<message>.*)'
        - directive: source
          attrs:
            - '@id': reddit_nginx_access_log
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: reddit.nginx.access
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
            - '@id': reddit_nginx_error_log
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: reddit.nginx.error
            - path: /var/log/nginx/error.log
            - pos_file: /var/log/nginx/error.log.pos
            - nested_directives:
                - directive: parse
                  attrs:
                    - '@type': regexp
                    - expression: '^(?<time>\d+\/\d+\/\d+\s\d+:\d+:\d+)\s(?<level_name>\[.*])\s(?<message>.*)'
        - {{ auth_log_filter('grep', 'user_agent', '/ELB-HealthChecker/', 'reddit.nginx.access') }}
        - {{ record_tagging |yaml() }}
        - {{ tls_forward |yaml() }}
