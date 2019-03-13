{% from "fluentd/record_tagging.jinja" import record_tagging with context %}

fluentd:
  plugins:
    - fluent-plugin-secure-forward
  configs:
    - name: ocwcms
      settings:
        - directive: source
          attrs:
            - '@id: ocwcms_apache_access_log'
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: ocwcms.apache.access
            - path: /var/log/apache2/access.log
            - pos_file: /var/log/apache2/access.log.pos
            - nested_directives:
              - directive: parse
                attrs:
                  - '@type': apache2
                  - keep_time_key: 'true'
        - directive: source
          attrs:
            - '@id: ocwcms_apache_error_log'
            - '@type':  tail
            - enable_watch_timer: 'false'
            - tag: ocwcms.apache.error
            - path: /var/log/apache2/error.log
            - pos_file: /var/log/apache2/error.log.pos
            - nested_directives:
              - directive: parse
                attrs:
                  - '@type': apache_error
        - directive: source
          attrs:
            - '@id: ocwcms_zope_event_log'
            - '@type': tail
            - enable_watch_timer: 'false'
            - tag: ocwcms.zope.event
            - path: /usr/local/Plone/zeocluster/var/client*/event.log
            - pos_file: /usr/local/Plone/zeocluster/var/client_event.log.pos
            - nested_directives:
              - directive: parse
                attrs:
                  - '@type': multiline
                  - format_firstline: '^------'
                  - format1: '------\n/'
                  - format2: '(?<time>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}) '
                  - format3: '(?<level_name>[A-Z]+) (?<message>.*)'
        - directive: source
          attrs:
            - '@id: ocwcms_zope_access_log'
            - enable_watch_timer: 'false'
            - tag: ocwcms.zope.access
            - path: /usr/local/Plone/zeocluster/var/client*/Z2.log
            - pos_file: /usr/local/Plone/zeocluster/var/client_Z2.log.pos
            - nested_directives:
              - directive: parse
                attrs:
                  - '@type': apache2
                  - keep_time_key: 'true'
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
