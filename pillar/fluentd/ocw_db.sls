{% from "fluentd/record_tagging.jinja" import record_tagging with context %}
{% from "fluentd/tls_forward.jinja" import tls_forward with context %}

fluentd:
  configs:
    ocwdb:
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
        - {{ tls_forward |yaml() }}
