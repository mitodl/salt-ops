{% set relay_host = salt.pillar.get('edx:smtp:relay_host', 'outgoing.mit.edu') -%}
{% set relay_username = salt.pillar.get('edx:smtp:relay_username', 'mitxmail') -%}
{% set relay_password = salt.pillar.get('edx:smtp:relay_password', '') -%}

{% set root_forward = salt.pillar.get('edx:smtp:root_forward', 'cuddle-bunnies@mit.edu') -%}
{% set root_from = salt.pillar.get('edx:smtp:root_from', 'mitxmail@mit.edu') -%}


install_mailutils_package:
  pkg.installed:
    - pkgs:
      - mailutils
    - refresh: True
    - refresh_modules: True

create_password_maps_file:
  file.managed:
    - name: /etc/postfix/relay_passwd
    - source: salt://edx/templates/relay_passwd.j2
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
    - owner: root
    - group: root
    - mode: 600
    - context:
        root_from: {{ relay_host }}
