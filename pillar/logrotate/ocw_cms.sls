logrotate:
  zeoclient_event:
    conf_file: /etc/logrotate.d/zeoclient_event
    name: /usr/local/Plone/zeocluster/var/client1/event.log
    options:
      - rotate 3
      - monthly
      - prerotate /usr/local/Plone/zeocluster/var/client1/bin stop
      - postrotate /usr/local/Plone/zeocluster/var/client1/bin start
  zeoclient_z2:
    conf_file: /etc/logrotate.d/zeoclient_z2
    name: /usr/local/Plone/zeocluster/var/client1/Z2.log
    options:
      - rotate 3
      - monthly
      - prerotate /usr/local/Plone/zeocluster/var/client1/bin stop
      - postrotate /usr/local/Plone/zeocluster/var/client1/bin start
  {% if salt.grains.get('id') == 'ocw-production-cms-2' %}
  ocw_publishing_logs:
    conf_file: /etc/logrotate.d/ocw_publishing_logs
    name: /prod/OCWEngines/logs/*.{log|out}
    options:
      - rotate 3
      - monthly
      - prerotate /usr/local/Plone/zeocluster/var/client1/bin stop && kill $(ps aux | grep python | awk '{print $2}')
      - postrotate /usr/local/Plone/zeocluster/var/client1/bin start && nohup python enginescheduler.py PRODUCTION > /prod/OCWEngines/logs/production_nohup.log && nohup python enginescheduler.py CETOOL > /prod/OCWEngines/logs/cetool_nohup.out && nohup python enginescheduler.py MIRRORUPDATE > /prod/OCWEngines/logs/mirror_nohup.out
  {% endif %}
  zeoserver:
    conf_file: /etc/logrotate.d/zeoserver
    name: /usr/local/Plone/zeocluster/var/zeoserver/zeoserver.log
    options:
      - rotate 3
      - monthly
      - copytruncate
      - notifempty
