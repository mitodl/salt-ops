
manage_plone_env_vars:
  file.managed:
    - name: /usr/local/Plone/zeocluster/parts/client1/etc/zope.conf
    - template: jinja
    - source: salt://apps/ocw/templates/zope.conf.jinja
    - user: root
    - group: root
    - mode: '0644'
