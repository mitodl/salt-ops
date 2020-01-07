{% from "fluentd/record_tagging.jinja" import record_tagging with context %}
{% from "fluentd/auth_log.jinja" import auth_log_source, auth_log_filter with context %}
{% from "fluentd/tls_forward.jinja" import tls_forward with context %}

fluentd:
  configs:
    xqwatcher:
      settings:
        - directive: source
          attrs:
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: edx.xqwatcher.{{ salt.grains.get('course', 'none') }}
            - path: /edx/var/log/xqwatcher/xqwatcher.log
            - pos_file: /edx/var/log/xqwatcher/xqwatcher.log.pos
            - format: multiline
            - format_firstline: '/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d+ /'
            - format1: '/^(?<time>^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d+) - (?<file_name>.*?):(?<line_number>\d+) -- (?<function_name>\w+) \[(?<log_level>\w+)\]: (?<message>.*)/'
            - time_format: '%Y-%m-%d %H:%M:%S,%L'
            - multiline_flush_interval: '5s'
        - directive: source
          attrs:
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: edx.xqwatcher.{{ salt.grains.get('course', 'none') }}.stderr
            - path: /edx/var/log/supervisor/xqwatcher-stderr.log
            - pos_file: /edx/var/log/supervisor/xqwatcher-stderr.log.pos
            - format: multiline
            - format_firstline: '/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d+ /'
            - format1: '/^(?<time>^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d+) - (?<file_name>.*?):(?<line_number>\d+) -- (?<function_name>\w+) \[(?<log_level>\w+)\]: (?<message>.*)/'
            - time_format: '%Y-%m-%d %H:%M:%S,%L'
            - multiline_flush_interval: '5s'
        - directive: source
          attrs:
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: edx.xqwatcher.{{ salt.grains.get('course', 'none') }}.stdout
            - path: /edx/var/log/supervisor/xqwatcher-stdout.log
            - pos_file: /edx/var/log/supervisor/xqwatcher-stdout.log.pos
            - format: 'none'
        - {{ record_tagging |yaml() }}
        - {{ tls_forward |yaml() }}
