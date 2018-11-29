{% set users = ['fsuser', 'ocwuser'] %}
{% set root_directory = '/var/www/ocw' %}
{% set directories = ['about', 'courses', 'donate', 'educator', 'faculty', 'give',
                     'help', 'high-school', 'icons', 'images', 'jsp', 'jw-player-free',
                     'jwplayer', 'OcwWeb', 'ocw-labs', 'resources', 'rss', 'scp48112',
                     'scripts', 'search', 'styles', 'subscribe', 'support', 'terms',
                     'webfonts', 'xml', 'xsd'] %}
{% set pkgs = ['git'] %}

{% for user in users %}
create_{{ user }}_user:
  user.present:
    - name: {{ user }}
    - shell: /bin/bash

set_{{ user }}_ssh_auth_key:
  module.run:
    - name: ssh.set_auth_key
    - user: {{ user }}
    - key: __vault__::secret-open-courseware/production/ssh_keys/{{ user }}>data>value
{% endfor %}

create_{{ root_directory }}_directory:
  file.directory:
    - name: {{ root_directory }}
    - user: fsuser
    - group: www-data
    - makedirs: True
    - require:
      - user: create_fsuser_user

install_{{ pkgs }}:
  pkg.installed:
    - pkgs: {{ pkgs }}
    - refresh: True
    - refresh_modules: True

{% for dir in directories %}
create_{{ dir }}_directory:
  file.directory:
    - name: {{ root_directory }}/{{ dir }}
    - user: fsuser
    - group: www-data
    - makedirs: True
    - require:
      - file: create_{{ root_directory }}_directory
{% endfor %}
