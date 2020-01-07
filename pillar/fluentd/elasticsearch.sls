{% from "fluentd/record_tagging.jinja" import record_tagging with context %}
{% from "fluentd/auth_log.jinja" import auth_log_source, auth_log_filter with context %}

fluentd:
  configs:
    elasticsearch_server:
      settings:
        - directive: source
          attrs:
            - '@type': tail
            - tag: elasticsearch.server
            - enable_watch_timer: 'false'
            - path: /usr/share/elasticsearch/logs/*.log
            - pos_file: /usr/share/elasticsearch/logs/elasticsearch_fluentd.log.pos
            - format: multiline
            - format_firstline: '/^\[\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2},\d{3}\]/'
            - format1: '/^\[(?<time>\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2},\d{3})\]\[(?<log_level>\w+)\]\[(?<module_name>.*?)\] (?<message>.*)$/'
            - multiline_flush_interval: '5s'
        - {{ auth_log_source('syslog.auth', '/var/log/auth.log') }}
        - {{ auth_log_filter('grep', 'ident', '/CRON/') }}
        - {{ record_tagging |yaml() }}
        - {{ tls_forward |yaml() }}
