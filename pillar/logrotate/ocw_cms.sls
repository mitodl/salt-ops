logrotate:
  zeoclient_event:
    name: /usr/local/Plone/zeocluster/var/client1/event.log
    options:
      - rotate 3
      - monthly
      - copytruncate
      - notifempty
      - compress
      - delaycompress
  zeoclient_z2:
    name: /usr/local/Plone/zeocluster/var/client1/Z2.log
    options:
      - rotate 3
      - monthly
      - copytruncate
      - notifempty
      - compress
      - delaycompress
  {% if salt.grains.get('ocw-cms-role') == 'engine' %}
  ocw_publishing_logs:
    name: /mnt/ocwfileshare/OCWEngines/logs/*.{log|out}
    options:
      - rotate 7
      - daily
      - copytruncate
      - notifempty
      - compress
      - delaycompress
  {% endif %}
  zeoserver:
    name: /usr/local/Plone/zeocluster/var/zeoserver/zeoserver.log
    options:
      - rotate 3
      - monthly
      - copytruncate
      - notifempty
      - compress
      - delaycompress
