{% set relay_host = salt.pillar.get('edx:smtp:relay_host', 'outgoing.mit.edu') -%}
{% set relay_username = salt.pillar.get('edx:smtp:relay_username', 'mitxmail') -%}
{% set relay_password = salt.pillar.get('edx:smtp:relay_password', '') -%}

{% set root_forward = salt.pillar.get('edx:smtp:root_forward', 'cuddle-bunnies@mit.edu') -%}
{% set root_from = salt.pillar.get('edx:smtp:root_from', 'mitxmail@mit.edu') -%}


install_mailutils_package:
  pkg.installed:
    - pkg: mailutils
    - refresh: True
    - refresh_modules: True

create_password_maps_file:
  file.managed:
    - name: /etc/postfix/relay_passwd
    - source: salt://edx/templates/relay_passwd.j2
    - template: jinja
    - owner: root
    - group: root
    - mode: 600
    - context:
        relay_host: {{ relay_host }}
        relay_username: {{ relay_username }}
        relay_password: {{ relay_password }}

create_canonical_file:
  file.managed:
    - name: /etc/postfix/canonical
    - source: salt://edx/templates/canonical.j2
    - template: jinja
    - owner: root
    - group: root
    - mode: 600
    - context:
        root_from: {{ relay_host }}

configure_postfix_relay:
  file.managed:
    - name: /etc/postfix.main.cf
    - source: salt://edx/templates/postfix_main.cf.j2
    - template: jinja

forward_root_email:
  alias.present:
    - name: root
    - target: {{ root_forward }}

relay_postmap:
  cmd.watch:
    - name: /usr/sbin/postmap /etc/postfix/relay_passwd
    - watch:
      - file: configure_postfix_relay

canonical_postmap:
  cmd.watch:
    - name: /usr/sbin/postmap /etc/postfix/canonical
    - watch:
      - file: create_canonical_file

postfix_service:
  service.running:
    - name: postfix
    - enable: True
    - reload: True
    - watch:
      - file: configure_postfix_relay
      - cmd: relay_postmap
      - cmd: canonical_postmap
      - alias: forward_root_email
