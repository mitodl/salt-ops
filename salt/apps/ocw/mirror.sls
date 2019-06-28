{% set mirror_rootdirectory = salt.pillar.get('ocw:mirror:rootdirectory') %}
{% set data_dirs = salt.pillar.get('ocw:mirror:data_dirs') %}
{% set fs_owner = salt.pillar.get('ocw:mirror:fs_owner') %}
{% set fs_group = salt.pillar.get('ocw:mirror:fs_group') %}
{% set host_aliases = salt.pillar.get('ocw:mirror:host_aliases') %}

install_python_lxml:
  pkg.installed:
    - name: python-lxml

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

# We need these /etc/hosts aliases because there are hardcoded hostnames in the
# shell scripts that run on the mirror server.
{% for alias in host_aliases %}
alias_{{ alias[0] }}_for_mirror_script:
  module.run:
    - name: hosts.set_host
    - alias: {{ alias[0] }}
    - ip: {{ alias[1] }}
{% endfor %}
