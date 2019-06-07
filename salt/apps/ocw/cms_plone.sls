
manage_plone_env_vars:
  file.managed:
    - name: /usr/local/Plone/zeocluster/parts/client1/etc/zope.conf
    - template: jinja
    - source: salt://apps/ocw/templates/zope.conf.jinja
    - user: root
    - group: root
    - mode: '0644'

# Restart Plone nightly in order to avoid out-of-memory issues. This should
# be done after normal working hours and sufficiently ahead of any cron jobs,
# such as those defined in engines.sls.
restart_cms_cronjob:
  cron.present:
    - identifier: restart_cms
    - name: /usr/local/Plone/zeocluster/bin/client1 restart > /var/log/restart_cms.log 2>&1
    - user: root
    - minute: 30
    - hour: 3
