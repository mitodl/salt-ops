{% from "fluentd/record_tagging.jinja" import record_tagging with context %}

fluentd:
  overrides:
    pkgs:
      - ruby2.3
      - ruby2.3-dev
      - build-essential
  plugins:
    - fluent-plugin-secure-forward
    - fluent-plugin-keyvalue-parser
  configs:
    - name: reddit
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
                    - expression: '^(?<time>\w\d{4}\s\d{2}:\d{2}:\d{2}.\d{6})\s(?<code_value>\d+)\s(?<file_name>.*):(?<line_num>\d+)\]\s(?<message>.*)$'
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
                    - null_value_pattern: '-'
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
                    - expression: '^(?<time>\d+\/\d+\/\d+\s\d+:\d+:\d+)\s(?<level_name>\[.*])\s(?<message>.*)client:\s(?<client_ip>\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}),\sserver:\s(?<server>.*),\srequest:\s"(?<method>.*)",\supstream:\s"(?<upstream>.*)",\shost:\s"(?<host>\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3})"$'
        - {{ record_tagging |yaml() }}
        - directive: match
          directive_arg: '**'
          attrs:
            - '@type': secure_forward
            - self_hostname: {{ salt.grains.get('ipv4')[0] }}
            - secure: 'false'
            - flush_interval: '10s'
            - shared_key: __vault__::secret-operations/global/fluentd_shared_key>data>value
            - nested_directives:
                - directive: server
                  attrs:
                    - host: fluentd.service.operations.consul
                    - port: 5001
