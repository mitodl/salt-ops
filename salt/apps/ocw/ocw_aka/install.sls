{% set users = [fsuser, ocwuser, sshacs] %}
{% set root_directory = '/ocwdata/apache-tomcat/webapps/' %}
{% set directories = ['about', 'course', 'donate', 'educator', 'faculty', 'give',
                     'help', 'high-school', 'icons', 'images', 'jsp', 'jw-player-free',
                     'jwplayer', 'OcwWeb', 'ocw-labs', 'resources', 'rss', 'scp48112',
                     'scripts', 'search', 'styles', 'subscribe', 'support', 'terms',
                     'webfonts', 'xml', 'xsd'] %}

{% for user in users %}
create_{{ user }}_user:
  - name: {{ user }}
  - shell: /bin/bash
{% endfor %}

create_{{ root_directory }}_directory:
  file.directory:
    - name: {{ root_directory }}
    - user: fsuser
    - group: www-data
    - makedirs: True
    - require:
      - user: create_{{ user }}_user
      - file: create_{{ root_directory }}_directory

{% for dir in directories %}
create_{{ dir }}_directory:
  file.directory:
    - name: {{ dir }}
    - user: fsuser
    - group: www-data
    - makedirs: True
    - require:
      - user: create_{{ user }}_user
      - file: create_{{ root_directory }}_directory
{% endfor %}
