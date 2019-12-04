logrotate:
  kibana:
    name: /var/log/kibana.log
    options:
      - rotate 4
      - weekly
      - copytruncate
      - notifempty
      - compress
      - delaycompress
