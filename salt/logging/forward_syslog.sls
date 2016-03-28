remove_old_syslog_forwarding_config:
  file.absent:
    - name: /etc/rsyslog.d/99-syslog_server.conf

forward_syslog_to_local_fluentd:
  file.managed:
    - name: /etc/rsyslog.d/99-syslog_local_fluentd.conf
    - contents: |
        *.* @127.0.0.1:5140

restart_syslog_for_config_change:
  service.running:
    - name: rsyslog
    - watch:
        - file: forward_syslog_to_local_fluentd
