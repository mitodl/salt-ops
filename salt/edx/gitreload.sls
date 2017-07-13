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
    'DJANGO_SETTINGS': 'aws'
}) -%}
{% set gr_repo = salt.pillar.get('edx:gitreload:gr_repo',
                                 'github.com/mitodl/gitreload') -%}
{% set gr_repos = salt.pillar.get('edx:gitreload:gr_repos', []) -%}
{% set gr_version = salt.pillar.get('edx:gitreload:gr_version',
                                    'ba53a4b0e0618891535aa9107c3d113227540e39') -%}
{% set ssh_hosts = salt.pillar.get('edx:ssh_hosts',
   [{'name': 'github.com', 'fingerprint': 'SHA256:br9IjFspm1vxR3iA35FWE+4VTyz1hYVLIE2t1/CeyWQ'},
    {'name': 'github.mit.edu', 'fingerprint': 'SHA256:mP1vMrsRkP6l42bs0dsXejq3YgxMD2r5NqboImqssw0'}]) %}
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
    - fingerprint: {{ host.fingerprint }}
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
    - name: git+https://{{ gr_repo }}@{{ gr_version }}#egg=gitreload-latest
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
    - restart: True
    - require:
      - file: configure_gitreload_service
