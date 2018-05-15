{% from "fluentd/record_tagging.jinja" import record_tagging with context %}
{% from "fluentd/auth_log.jinja" import auth_log_source, auth_log_filter with context %}

fluentd:
  plugins:
    - fluent-plugin-secure-forward
  configs:
    - name: mongodb_server
      settings:
        - directive: source
          attrs:
            - '@type': tail
            - enable_watch_timer: 'false'
            - path: /var/log/mongodb/mongodb.log
            - pos_file: /var/log/mongodb/mongodb.log.pos
            - format: '/^(?<time>\d{4}-\d{2}-\d{2}\w\d{2}:\d{2}:\d{2}\W\d{3}\W\d{4}) ?(?<severity>\w)? ?(?<component>\w+)?\s+\[(?<context>\w+)\] (?<message>.*)$/'
            - tag: mongodb.server
        - directive: source
          attrs:
            - '@type': tail
            - enable_watch_timer: 'false'
            - path: /var/log/mongodb/mongod.log
            - pos_file: /var/log/mongodb/mongod.log.pos
            - format: '/^(?<time>\d{4}-\d{2}-\d{2}\w\d{2}:\d{2}:\d{2}\W\d{3}\W\d{4}) ?(?<severity>\w)? ?(?<component>\w+)?\s+\[(?<context>\w+)\] (?<message>.*)$/'
            - tag: mongodb.server
        - {{ auth_log_source('syslog.auth', '/var/log/auth.log') }}
        - {{ auth_log_filter('grep', 'ident', 'CRON') }}
        - {{ record_tagging |yaml() }}
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
                  - host: fluentd.service.operations.consul
                  - port: 5001
