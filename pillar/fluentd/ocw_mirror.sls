{% from "fluentd/record_tagging.jinja" import record_tagging with context %}
{% set pos_filename = '/data2/ocwmirror_logs.pos' %}

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
            - pos_file: {{ pos_filename }}
            - nested_directives:
              - directive: parse
                attrs:
                  - '@type': regexp
                  - expression: '^(<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) (?<message>.*)'
        - directive: source
          attrs:
            - '@id': ocwmirror_ia_log
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: ocwmirror.iadownload
            - path: /data2/internet_archive_content_download.log
            - pos_file: {{ pos_filename }}
            - nested_directives:
              - directive: parse
                attrs:
                  - '@type': multiline
                  - format_firstline: '/^--\d{4}-\d{2}-\d{2}/'
                  - format1: '/^--(?<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})--/'
                  - format2: '/\s+(?<url>.*?)\s+(?<message>.*)/'
        - directive: source
          attrs:
            - '@id': ocwmirror_akamai_log
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: ocwmirror.akamaidownload
            - path: /data2/akamai_content_download.log
            - pos_file: {{ pos_filename }}
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
