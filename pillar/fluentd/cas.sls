{% from "fluentd/record_tagging.jinja" import record_tagging with context %}
{% from "fluentd/auth_log.jinja" import auth_log_source, auth_log_filter with context %}

fluentd:
  plugins:
    - fluent-plugin-secure-forward
  configs:
    - name: auth_server
      settings:
        - directive: source
          attrs:
            - tag: cas.mitx.shibboleth.error
            - '@type': tail
            - enable_watch_timer: 'false'
            - path: /var/log/apache2/mitx_shibboleth_error.log
            - pos_file: /var/log/apache2/mitx_shibboleth_error.log.pos
            - format: apache_error
        - directive: source
          attrs:
            - tag: cas.mitx.shibboleth.access
            - '@type': tail
            - enable_watch_timer: 'false'
            - path: /var/log/apache2/mitx_shibboleth_access.log
            - pos_file: /var/log/apache2/mitx_shibboleth_access.log.pos
            - format: apache2
            - time_format: '%d/%b/%Y:%H:%M:%S'
        - directive: source
          attrs:
            - tag: cas.django
            - '@type': tail
            - enable_watch_timer: 'false'
            - path: /opt/cas/log/django.log
            - pos_file: /opt/cas/log/django.log.pos
            - format: multiline
            - format_firstline: '/^\[\d{1,2}\/\w{3}\/\d{4}\s+\d{2}:\d{2}:\d{2}\]/'
            - format1: '/^\[(?<time>\d{1,2}\/\w{3}\/\d{4}\s+\d{2}:\d{2}:\d{2})\] (?<log_level>\w+) \[(?<module_name>[a-zA-Z0-9-_.]+):(?<line_number>\d+)\] (?<message>.*)/'
            - time_format: '%d/%b/%Y %H:%M:%S'
            - multiline_flush_interval: '5s'
        - directive: filter
          directive_arg: '**'
          attrs:
            - '@type': grep
            - exclude1: agent Amazon Route 53 Health Check Service
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
                  - host: log-input.odl.mit.edu
                  - port: 5001
