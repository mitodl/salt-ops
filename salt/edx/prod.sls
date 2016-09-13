{% set data_path = '/tmp/edx_config' -%}
{% set venv_path = '/tmp/edx_config/venv' -%}
{% set repo_path = '/tmp/edx_config/configuration' -%}
{% set conf_file = '/tmp/edx_config/edx-sandbox.conf' -%}
{% set git_export_path = salt.pillar.get('edxapp:EDXAPP_GIT_REPO_EXPORT_DIR',
                                         '/edx/var/edxapp/export_course_repos') -%}
{% set git_servers = salt.pillar.get('edx:ssh_hosts',
                                     [{'name': 'github.com',
                                       'fingerprint': '16:27:ac:a5:76:28:2d:36:63:1b:56:4d:eb:df:a6:48'},
                                      {'name': 'github.mit.edu',
                                       'fingerprint': '64:a1:32:63:b4:7f:a6:98:c9:20:e2:b8:bc:10:09:57'}]) -%}
{% set playbooks = salt.pillar.get('edx:playbooks',
                                   ['edx-east/common.yml',
                                    'edx-east/forum.yml',
                                    'edx-east/xqueue.yml',
                                    'edx-east/xqwatcher.yml',
                                    'edx-east/edxapp.yml',
                                    'edx-east/worker.yml']) -%}
{% set theme_repo = salt.pillar.get('edx:edxapp:custom_theme:repo', 'https://github.com/mitocw/edx-theme') -%}
{% set theme_name = salt.pillar.get('edx:edxapp:THEME_NAME', None) -%}
{% set theme_branch = salt.pillar.get('edx:edxapp:custom_theme:branch', 'mitx') -%}
{% set theme_dir = salt.pillar.get('edx:edxapp:EDXAPP_COMPREHENSIVE_THEME_DIR', '/edx/app/edxapp/themes') -%}

configure_git_ppa_for_edx:
  pkgrepo.managed:
    - ppa: git-core/ppa
    - require_in:
        - pkg: install_os_packages

configure_python_ppa_for_edx:
  pkgrepo.managed:
    - ppa: fkrull/deadsnakes-python2.7
    - require_in:
        - pkg: install_os_packages

install_os_packages:
  pkg.installed:
    - pkgs:
        - git
        - libmysqlclient-dev
        - mysql-client
        - python2.7: 2.7.12-1~precise1
        - python2.7-dev: 2.7.12-1~precise1
        - python-pip
        - python-virtualenv
        - nfs-common
        - postfix
    - refresh: True
    - refresh_modules: True

clone_edx_configuration:
  file.directory:
    - name: {{ repo_path }}
    - makedirs: True
  git.latest:
    - name: {{ salt.pillar.get('edx:config:repo', 'https://github.com/edx/configuration.git') }}
    - rev: {{ salt.pillar.get('edx:config:branch', 'named-release/dogwood.3') }}
    - target: {{ repo_path }}
    - user: root
    - force_checkout: True
    - force_clone: True
    - force_reset: True
    - require:
      - file: clone_edx_configuration

mark_ansible_as_editable:
  file.replace:
    - name: {{ repo_path }}/requirements.txt
    - pattern: |
        ^git\+https://github\.com/edx/ansible.*
    - repl: |
        -e git+https://github.com/edx/ansible.git@stable-1.9.3-rc1-edx#egg=ansible==1.9.3-edx
    - require:
      - git: clone_edx_configuration

replace_nginx_static_asset_template_fragment:
  file.managed:
    - name: {{ repo_path }}/playbooks/roles/nginx/templates/edx/app/nginx/sites-available/static-files.j2
    - source: salt://edx/files/nginx_static_assets.j2
    - require:
        - git: clone_edx_configuration

create_ansible_virtualenv:
  # Note: We need to use a virtualenv over here because the Salt minion bootstrap
  #       installs some OS `python-` packages that are also pulled in by the edX
  #       config requirements for Ansible (e.g. python-jinja). This causes python
  #       package metadata issues, resulting in Ansible not being able to import
  #       dependencies at runtime.
  virtualenv.managed:
    - name: {{ venv_path }}
    - requirements: {{ repo_path }}/requirements.txt
    - require:
      - git: clone_edx_configuration
      - pkg: install_os_packages
      - file: replace_nginx_static_asset_template_fragment

place_ansible_environment_configuration:
  file.managed:
    - name: {{ conf_file }}
    - source: salt://edx/templates/ansible_env_config.yml.j2
    - template: jinja
    - makedirs: True

{% if salt.pillar.get('edx:generate_tls_certificate') %}
generate_self_signed_certificate:
  module.run:
    - name: tls.create_self_signed_cert
    - CN: {{ salt.pillar.get('edx:ansible_env_config:TLS_KEY_NAME') }}
    - replace: True
    - require_in:
      - cmd: run_ansible
{% else %}
{%
  set key_path = '{}/{}'.format(
    salt.pillar.get('edx:edxapp:TLS_LOCATION'),
    salt.pillar.get('edx:edxapp:TLS_KEY_NAME')
  )
%}
{% for ext in ['crt', 'key'] %}
place_tls_{{ ext }}_file:
  file.managed:
    - name: {{ key_path }}.{{ ext }}
    - contents_pillar: {{ 'edx:tls_{}'.format(ext) }}
    - user: root
    - group: root
    - mode: 600
    - makedirs: True
    - require_in:
      - cmd: run_ansible
{% endfor %}
{% endif %}

mount_efs_filesystem_for_course_assets:
  mount.mounted:
    - name: /mnt/data
    - device: {{ salt.grains.get('ec2:availability_zone', 'us-east-1b')|trim }}.{{ salt.pillar.get('edx:efs_id')|trim }}.efs.us-east-1.amazonaws.com:/
    - fstype: nfs4
    - mkmnt: True
    - persist: True
    - mount: True

{# Creating the edxapp user here so that it is present for setting appropriate
   file and directory ownership #}
create_edxapp_user:
  user.present:
    - name: edxapp
    - home: /edx/app/edxapp
    - createhome: False
    - shell: /bin/false

{% if theme_name %}
install_edxapp_theme:
  file.directory:
    - name: {{ theme_dir }}
    - makedirs: True
    - user: edxapp
    - group: edxapp
  git.latest:
    - name: {{ theme_repo }}
    - branch: {{ theme_branch }}
    - target: {{ theme_dir }}/{{ theme_name }}
    - user: edxapp
    - force_checkout: True
    - force_clone: True
    - force_reset: True
    - update_head: True
    - require:
      - file: install_edxapp_theme
    - require_in:
      - cmd: run_ansible
{% endif %}

remove_course_asset_symlink_before_ansible_run:
  file.absent:
    - name: /edx/var/edxapp/course_static

run_ansible:
  cmd.script:
    - name: {{ data_path }}/run_ansible.sh
    - source: salt://edx/templates/run_ansible.sh.j2
    - template: jinja
    - cwd: {{ repo_path }}/playbooks
    - context:
        data_path: {{ data_path }}
        venv_path: {{ venv_path }}
        repo_path: {{ repo_path }}
        conf_file: {{ conf_file }}
        playbooks: {{ playbooks }}
    - require:
      - virtualenv: create_ansible_virtualenv
    - unless: {{ salt.pillar.get('edx:skip_ansible', False) }}

create_course_asset_symlink:
  file.symlink:
    - name: /edx/var/edxapp/course_static
    - target: {{ salt.pillar.get('edx:edxapp:GIT_REPO_DIR') }}
    - makedirs: True
    - force: True
    - user: edxapp
    - group: www-data

{# Steps to enable git export for courses #}
make_git_export_directory:
  file.directory:
    - name: {{ git_export_path }}
    - user: www-data
    - group: www-data
    - makedirs: True

add_private_ssh_key_to_www-data_for_git_export:
  file.managed:
    - name: /var/www/.ssh/id_rsa
    - contents_pillar: edx:ssh_key
    - mode: 0600
    - makedirs: True
    - dir_mode: 0700
    - user: www-data
    - group: www-data

{% for host in git_servers %}
add_{{ host.name }}_to_known_hosts_for_edxapp:
  ssh_known_hosts.present:
    - name: {{ host.name }}
    - user: www-data
    - fingerprint: {{ host.fingerprint }}
{% endfor %}

update_max_upload_size_for_lms:
  file.replace:
    - name: /etc/nginx/sites-enabled/lms
    - pattern: 'client_max_body_size\s+\d+.M;'
    - repl: 'client_max_body_size {{ salt.pillar.get("edx:edxapp:max_upload_size", "20") }}M;'
    - backup: False
  service.running:
    - name: nginx
    - reload: True
    - watch:
        - file: update_max_upload_size_for_lms

configure_nginx_status_module_for_edx:
  file.managed:
    - name: /etc/nginx/sites-enabled/status_monitor
    - contents: |
        server {
            listen 127.0.0.1:80;
            location /nginx_status {
                stub_status on;
                access_log off;
                allow 127.0.0.1;
                deny all;
            }
        }
    - group: www-data
  service.running:
    - name: nginx
    - reload: True
    - watch:
        - file: configure_nginx_status_module_for_edx
