{% from "fluentd/record_tagging.jinja" import record_tagging with context %}
{% from "fluentd/tls_forward.jinja" import tls_forward with context %}

fluentd:
  configs:
    - name: ocwmirror
      settings:
        - directive: source
          attrs:
            - '@id': ocwmirror_update_log
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: ocwmirror.update
            - path: /data2/mirror_update.log
            - pos_file: /data2/mirror_update_log.pos
            - nested_directives:
              - directive: parse
                attrs:
                  - '@type': regexp
                  - expression: '^(?<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) (?<message>.*)'
        - directive: source
          attrs:
            - '@id': ocwmirror_download_logs
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: ocwmirror.download
            - path: /data2/*_download.log
            - pos_file: /data2/content_download_logs.pos
            - nested_directives:
              - directive: parse
                attrs:
                  - '@type': multiline
                  - format_firstline: '/^--\d{4}-\d{2}-\d{2}/'
                  - format1: '/^--(?<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})--/'
                  - format2: '/\s+(?<url>.*?)\s+(?<message>.*)/'
        - {{ record_tagging | yaml() }}
        - {{ tls_forward |yaml() }}
