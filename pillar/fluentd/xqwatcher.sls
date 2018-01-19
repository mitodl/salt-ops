{% from "fluentd/record_tagging.jinja" import record_tagging with context %}
{% from "fluentd/auth_log.jinja" import auth_log_source, auth_log_filter with context %}

fluentd:
  plugins:
    - fluent-plugin-secure-forward
  configs:
    - name: xqwatcher
      settings:
        - directive: source
          attrs:
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: edx.xqwatcher
            - path: /edx/var/log/xqwatcher/xqwatcher.log
            - pos_file: /edx/var/log/xqwatcher/xqwatcher.log.pos
            - format: multiline
            - format_firstline: '/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d+ /'
            - format1: '/^(?<time>^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d+) - (?<file_name>.*?):(?<line_number>\d+) -- (?<function_name>\w+) \[(?<log_level>\w+)\]: (?<message>.*)/'
            - time_format: '%Y-%m-%d %H:%M:%S,%L'
            - multiline_flush_interval: '5s'
        - {{ record_tagging |yaml() }}
        - directive: match
          directive_arg: '**'
          attrs:
            - '@type': secure_forward
            - self_hostname: {{ salt.grains.get('ipv4')[0] }}
            - secure: 'false'
            - flush_interval: '10s'
            - shared_key: {{ salt.vault.read('secret-operations/global/fluentd_shared_key').data.value }}
            - nested_directives:
                - directive: server
                  attrs:
                    - host: fluentd.service.operations.consul
                    - port: 5001
