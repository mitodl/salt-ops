{% from "fluentd/record_tagging.jinja" import record_tagging with context %}

fluentd:
  plugins:
    - fluent-plugin-secure-forward
  configs:
    - name: ocwdb
      settings:
        - directive: source
          attrs:
            - '@id': ocwdb_zeoserver_log
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: ocwdb.zope.log
            - path: /usr/local/Plone/zeocluster/var/zeoserver/zeoserver.log
            - pos_file: /usr/local/Plone/zeocluster/var/zeoserver/zeoserver.log.pos
            - nested_directives:
              - directive: parse
                attrs:
                  - '@type': regexp
                  - expression: '^(?<time>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}) \[(?<level_name>.*?)\] (?<message>.*)'
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
