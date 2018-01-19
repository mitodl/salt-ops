{% from "fluentd/record_tagging.jinja" import record_tagging with context %}
{% from "fluentd/auth_log.jinja" import auth_log_source, auth_log_filter with context %}

fluentd:
  plugins:
    - fluent-plugin-secure-forward
  configs:
    - name: elasticsearch_server
      settings:
        - directive: source
          attrs:
            - '@type': tail
            - tag: elasticsearch.server
            - enable_watch_timer: 'false'
            - path: /var/log/elasticsearch/*.log
            - pos_file: /var/log/elasticsearch/elasticsearch_fluentd.log.pos
            - format: multiline
            - format_firstline: '/^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}\]/'
            - format1: '/^\[(?<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3})\]\[(?<log_level>\w+)\]\[(?<module_name>.*?)\] (?<message>.*)$/'
            - multiline_flush_interval: '5s'
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
            - shared_key: {{ salt.vault.read('secret-operations/global/fluentd_shared_key').data.value }}
            - nested_directives:
              - directive: server
                attrs:
                  - host: fluentd.service.operations.consul
                  - port: 5001
