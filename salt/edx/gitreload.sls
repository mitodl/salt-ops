{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set env_settings = salt.pillar.get('environments:{}'.format(ENVIRONMENT)) %}

{% if 'live' in salt.grains.get('id') %}
{% set edx_type = 'live' %}
{% elif 'draft' in salt.grains.get('id') %}
{% set edx_type = 'draft' %}
{% endif %}

{% set purpose_name = salt.grains.get('purpose') %}
{% set purpose = env_settings.purposes[purpose_name] %}

{% set gr_dir = salt.pillar.get('edx:gitreload:gr_dir', '/edx/app/gitreload') -%}
{% set gr_env = salt.pillar.get('edx:gitreload:gr_env', {
    'PORT': 8095,
    'UPDATE_LMS': True,
    'REPODIR': '/mnt/data/repos',
    'LOG_LEVEL': 'debug',
    'WORKERS': 1,
    'LOGFILE': "/edx/var/log/gr/gitreload.log",
    'VIRTUAL_ENV': '/edx/app/edxapp/venvs/edxapp',
    'EDX_PLATFORM': '/edx/app/edxapp/edx-platform',
    'DJANGO_SETTINGS': 'production',
    'LMS_CFG': '/edx/etc/lms.yml'
}) -%}
{% set gr_repo = salt.pillar.get('edx:gitreload:gr_repo',
                                 'github.com/mitodl/gitreload') -%}
{% set gr_repos = salt.pillar.get('edx:gitreload:gr_repos', []) -%}
{% set gr_version = salt.pillar.get('edx:gitreload:gr_version',
                                    'ba53a4b0e0618891535aa9107c3d113227540e39') -%}
{% set ssh_hosts = salt.pillar.get('edx:ssh_hosts',
   [{'name': 'github.com', 'fingerprint': '9d:38:5b:83:a9:17:52:92:56:1a:5e:c4:d4:81:8e:0a:ca:51:a2:64:f1:74:20:11:2e:f8:8a:c3:a1:39:49:8f'},
    {'name': 'github.mit.edu', 'fingerprint': 'aa:d2:e9:66:7e:46:77:d3:7d:d9:39:3f:f4:9f:17:a1:18:c1:87:8f:69:cb:8f:d0:db:10:b7:71:5e:ad:57:68'}]) %}
{% set gr_log_dir = salt.pillar.get('edx:gitreload:gr_log_dir',
                                  '/edx/var/log/gr') -%}
{% set hostname = purpose.domains.gitreload -%}
{% set basic_auth = salt.pillar.get('edx:gitreload:basic_auth', {
  'username': 'mitx',
  'password': 'change_me',
  'location': '/edx/app/nginx/gitreload.htpasswd'
}) -%}

{% set gitreload_service = salt.grains.filter_by({
    'systemd': {
      'destination_path': '/lib/systemd/system/gitreload.service',
      'source_path': 'salt://edx/templates/gitreload_systemd.conf.j2',
    },
    'upstart': {
      'destination_path': '/etc/init/gitreload.conf',
      'source_path': 'salt://edx/templates/gitreload_init.conf.j2',
    }
  }, grain='init', merge=salt.pillar.get('gitreload:init_service')) %}

install_mit_github_ssh_key:
  file.managed:
    - name: /var/www/.ssh/id_rsa
    - user: www-data
    - group: www-data
    - contents_pillar: 'edx:ssh_key'
    - makedirs: True
    - mode: 0600
    - dir_mode: 0700

{% for host in ssh_hosts %}
add_{{ host.name }}_to_known_hosts_for_gitreload:
  ssh_known_hosts.present:
    - name: {{ host.name }}
    - user: www-data
    - enc: ssh-rsa
    - fingerprint: {{ host.fingerprint }}
    - fingerprint_hash_type: sha256
    - require:
      - file: install_mit_github_ssh_key
{% endfor %}

create_gitreload_config:
  file.managed:
    - name: {{ gr_dir }}/gr.env.json
    - source: salt://edx/templates/gitreload_config.json.j2
    - owner: www-data
    - group: www-data
    - template: jinja
    - context:
        gr_env: {{ gr_env }}
    - makedirs: True

install_gitreload:
  pip.installed:
    - name: gitreload==0.2.5
    - exists_action: w
    - bin_env: {{ gr_env.VIRTUAL_ENV }}
    - upgrade: True
    - user: edxapp

{% for path in [gr_dir, gr_log_dir, gr_env.REPODIR] %}
create_{{ path }}_directories:
  file.directory:
    - name: {{ path }}
    - user: www-data
    - group: www-data
    - makedirs: True
    - require_in:
      - file: configure_gitreload_service
{% endfor %}

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

import_{{ item.name }}_course:
  cmd.script:
    - source: salt://edx/templates/gitreload_import.sh.j2
    - template: jinja
    - context:
        gr_env: {{ gr_env }}
        item: {{ item }}
    - require:
      - git: pull_{{ item.name }}_repo
{% endfor %}

configure_gitreload_service:
  file.managed:
    - name: {{ gitreload_service.destination_path }}
    - source: {{ gitreload_service.source_path }}
    - template: jinja
    - mode: 644
    - context:
        gr_env: {{ gr_env }}
        gr_dir: {{ gr_dir }}
  {% if salt.grains.get('init') == 'systemd' %}
  cmd.wait:
    - name: systemctl daemon-reload
    - watch:
        - file: configure_gitreload_service
  {% endif %}

gitreload_htpasswd:
  file.managed:
    - name: {{ basic_auth.location }}
    - contents: {{ basic_auth.username }}:{{ salt['cmd.run']('openssl passwd -quiet -crypt {}'.format(basic_auth.password)) }}
    - user: www-data
    - group: www-data

gitreload_site:
  file.managed:
    - name: /edx/app/nginx/sites-available/gitreload
    - source: salt://edx/templates/gitreload_site.j2
    - template: jinja
    - mode: 640
    - makedirs: True
    - user: root
    - group: www-data
    - context:
        gr_env: {{ gr_env }}
        hostname: {{ hostname }}
        htpasswd: {{ basic_auth.location }}
    - require:
      - file: gitreload_htpasswd

enable_gitreload_link:
  file.symlink:
    - name: /etc/nginx/sites-enabled/gitreload
    - target: /edx/app/nginx/sites-available/gitreload
    - user: root
    - group: root
    - require:
      - file: gitreload_site

reload_nginx:
  service.running:
    - name: nginx
    - reload: True
    - watch:
      - file: enable_gitreload_link
      - file: gitreload_htpasswd
      - file: gitreload_site

start_gitreload:
  service.running:
    - name: gitreload
    - enable: True
    - require:
      - file: configure_gitreload_service
