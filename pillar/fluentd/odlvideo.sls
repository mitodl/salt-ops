{% from "fluentd/record_tagging.jinja" import record_tagging with context %}
{% from "fluentd/tls_forward.jinja" import tls_forward with context %}

fluentd:
  configs:
    odlvideo:
      settings:
        - directive: source
          attrs:
            - '@id': odlvideo_nginx_access_log
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: odlvideo.nginx.access
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
            - '@id': odlvideo_nginx_error_log
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: odlvideo.nginx.error
            - path: /var/log/nginx/error.log
            - pos_file: /var/log/nginx/error.log.pos
            - nested_directives:
                - directive: parse
                  attrs:
                    - '@type': regexp
                    - expression: '^(?<time>\d+\/\d+\/\d+\s\d+:\d+:\d+)\s(?<level_name>\[.*])\s(?<message>.*)'
        - directive: source
          attrs:
            - '@id': odlvideo_uwsgi_log
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: odlvideo.uwsgi
            - path: /var/log/odl-video-service.log
            - pos_file: /var/log/odl-video-service.log.pos
            - nested_directives:
                - directive: parse
                  attrs:
                    - '@type': json
                    - json_parser: json
                    - keep_time_key: 'true'
        - {{ record_tagging |yaml() }}
        - {{ tls_forward() }}
