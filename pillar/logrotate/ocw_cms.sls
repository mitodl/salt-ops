{% set ocw_cms_role = salt.grains.get('ocw-cms-role') %}

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
  {% if 'engine' in ocw_cms_role %}
  ocw_publishing_logs:
    name: /mnt/ocwfileshare/OCWEngines/logs/*.log
    options:
      - rotate 7
      - daily
      - copytruncate
      - notifempty
      - compress
      - delaycompress
  ocw_export_courses_json_log:
    name: /var/log/engines-cron/export_courses_json.log
    options:
      - rotate 4
      - weekly
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
