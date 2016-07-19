{% set gr_dir = salt.pillar.get('edx:gitreload:gr_dir') %}
{% set gr_env = salt.pillar.get('edx:gitreload:gr_env') %}
{% set gr_repo = salt.pillar.get('edx:gitreload:gr_repo') %}
{% set gr_repos = salt.pillar.get('edx:gitreload:gr_repos') %}
{% set gr_version = salt.pillar.get('edx:gitreload:gr_version') %}
{% set ssh_hosts = salt.pillar.get('edx:gitreload:ssh_hosts', ['github.com', 'github.mit.edu']) %}

install_mit_github_ssh_key:
  file.managed:
    - name: /var/www/.ssh/id_rsa
    - user: www-data
    - group: www-data
    - contents_pillar: 'edx:gitreload:ssh_key'
    - makedirs: True
    - mode: 0600
    - dir_mode: 0700

create_empty_known_hosts:
  file.managed:
    - name: /var/www/.ssh/known_hosts
    - user: www-data
    - group: www-data
    # Note: Contents is explicitly being set to empty here in order to overwrite
    # any existing known_hosts.
    - contents:
    - require:
      - file: install_mit_github_ssh_key

{% for item in ssh_hosts %}
save_{{ item }}_ssh_host_key:
  cmd.run:
    - name: ssh-keyscan {{ item }} >> /var/www/.ssh/known_hosts
    - runas: www-data
    - require:
      - file: create_empty_known_hosts
{% endfor %}

create_gitreload_config:
  file.managed:
    - name: {{ gr_dir }}/gr.env.json
    - owner: www-data
    - group: www-data
    - contents: {{ gr_env | json }}
    - makedirs: True

install_gitreload:
  pip.install:
    - name: {{ gr_env.VIRTUAL_ENV }}
    - pkgs: git+https://{{ gr_repo }}@{{ gr_version }}#egg=gitreload
    - exists_action: w

{% for item in gr_repos %}
pull_{{ item.name }}_repo:
  git.latest:
    - name: {{ item.url }}
    - target: {{ gr_env.REPODIR }}/{{ item.name }}
    - rev: {{ item.commit }}
    - user: www-data
    - require:
      {% for host in ssh_hosts %}
      - cmd: save_{{ host }}_ssh_host_key
      {% endfor %}
{% endfor %}

{% for item in gr_repos %}
import_{{ item }}_course:
  cmd.script:
    - source: salt://edx/templates/gitreload_import.sh.j2
    - template: jinja
    - context:
        gr_env: {{ gr_env }}
        item: {{ item }}
    - require:
      - git: pull_{{ item.name }}_repo
{% endfor %}

gitreload_init_script:
  file.managed:
    - name: /etc/init/gitreload.conf
    - source: salt://edx/templates/gitreload_init.conf.j2
    - template: jinja
    - mode: 644
    - context:
        gr_env: {{ gr_env }}
        gr_dir: {{ gr_dir }}

start_gitreload:
  service.running:
    - name: gitreload
    - enable: True
    - require:
      - file: gitreload_init_script
      - file: create_gitreload_config
