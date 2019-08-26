{% from "fluentd/record_tagging.jinja" import record_tagging with context %}

fluentd:
  plugins:
    - fluent-plugin-secure-forward
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
        - directive: match
          directive_arg: '**'
          attrs:
            - '@type': secure_forward
            - self_hostname: {{ salt.grains.get('ip4_interfaces:eth0')[0] }}
            - secure: 'false'
            - flush_interval: '10s'
            - shared_key: __vault__::secret-operations/global/fluentd_shared_key>data>value
            - nested_directives:
              - directive: server
                attrs:
                  - host: log-input.odl.mit.edu
                  - port: 5001
