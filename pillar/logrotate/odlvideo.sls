logrotate:
  odlvideo:
    name: /var/log/odl-video/django.log
    options:
      - rotate 7
      - daily
      - copytruncate
      - notifempty
      - compress
      - delaycompress
