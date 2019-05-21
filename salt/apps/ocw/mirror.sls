{% set mirror_rootdirectory = salt.pillar.get('ocw:mirror:rootdirectory') %}
{% set data_dirs = salt.pillar.get('ocw:mirror:data_dirs') %}
{% set fs_owner = salt.pillar.get('ocw:mirror:fs_owner') %}
{% set fs_group = salt.pillar.get('ocw:mirror:fs_group') %}

{% for dir in data_dirs %}
ensure_state_of_mirror_{{ dir }}_directory:
  file.directory:
    - name: {{ dir }}
    - user: {{ fs_owner }}
    - group: {{ fs_group }}
    - dir_mode: '0755'
    - makedirs: True
{% endfor %}

ensure_state_of_mirror_rootdirectory:
  file.directory:
    - name: {{ mirror_rootdirectory }}
    - user: {{ fs_owner }}
    - group: {{ fs_group }}
    - dir_mode: '0755'
    - makedirs: True
