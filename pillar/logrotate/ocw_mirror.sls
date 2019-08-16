
logrotate:
  mirror_update_log:
    name: /data2/mirror_update.log
    options:
      - rotate 6
      - monthly
      - copytruncate
      - notifempty
      - compress
