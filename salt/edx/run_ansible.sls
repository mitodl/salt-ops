{% set data_path = '/tmp/edx_config' -%}
{% set venv_path = '/tmp/edx_config/venv' -%}
{% set repo_path = '/tmp/edx_config/configuration' -%}
{% set conf_file = '/tmp/edx_config/edx-vars.conf' -%}

{% set playbooks = salt.pillar.get('edx:playbooks', ['edx-east/edxapp.yml',
                                                     'edx-east/xqueue.yml',
                                                     'edx-east/forum.yml']) -%}

clone_edx_configuration:
  file.directory:
    - name: {{ repo_path }}
    - makedirs: True
  git.latest:
    - name: {{ salt.pillar.get('edx:config:repo', 'https://github.com/edx/configuration.git') }}
    - rev: {{ salt.pillar.get('edx:config:branch', 'open-release/ginkgo.master') }}
    - branch: {{ salt.pillar.get('edx:config:branch', 'open-release/ginkgo.master') }}
    - target: {{ repo_path }}
    - user: root
    - force_checkout: True
    - force_clone: True
    - force_fetch: True
    - force_reset: True
    - require:
      - file: clone_edx_configuration

replace_nginx_static_asset_template_fragment:
  file.managed:
    - name: {{ repo_path }}/playbooks/roles/nginx/templates/edx/app/nginx/sites-available/static-files.j2
    - template: jinja
    - source: salt://edx/templates/nginx_static_assets.j2
    - require:
        - git: clone_edx_configuration

manage_extra_locations_lms_config:
  file.managed:
    - name: {{ repo_path }}/playbooks/roles/nginx/templates/edx/app/nginx/sites-available/extra_locations_lms.j2
    - template: jinja
    - source: salt://edx/templates/extra_locations_lms.j2
    - require:
        - git: clone_edx_configuration

add_mitx_devstack_playbook:
  file.managed:
    - name: {{ repo_path }}/playbooks/mitx_devstack.yml
    - source: salt://edx/files/mitx_devstack.yml
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
    - system_site_packages: {{ 'juniper' in grains.get('edx_codename', "") }}
    - no_setuptools: True
    - require:
      - git: clone_edx_configuration
      - file: replace_nginx_static_asset_template_fragment

place_ansible_environment_configuration:
  file.managed:
    - name: {{ conf_file }}
    - contents: |
        {{ salt.pillar.get('edx:ansible_vars')|yaml(False)|indent(8) }}
    - makedirs: True

{# Creating the edxapp user here so that it is present for setting appropriate
   file and directory ownership #}
create_edxapp_user:
  user.present:
    - name: edxapp
    - home: /edx/app/edxapp
    - createhome: False
    - shell: /bin/false

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
        playbooks: {{ playbooks|tojson }}
        extra_flags: "{{ salt.pillar.get('edx:ansible_flags', ' ') }}"
    - require:
      - virtualenv: create_ansible_virtualenv
    - unless: {{ salt.pillar.get('edx:skip_ansible', False) }}
    - env:
        HOME: /root

update_max_upload_for_lms:
  file.replace:
    - name: /etc/nginx/sites-enabled/lms
    - pattern: 'client_max_body_size\s+\d+M;'
    - repl: 'client_max_body_size {{ salt.pillar.get("edx:edxapp:max_upload_size", "20") }}M;'
    - backup: False
    - require:
        - cmd: run_ansible

set_expired_csrf_token_for_lms
  file.line:
    - name: /etc/nginx/sites-enabled/lms
    - mode: ensure
    - content: add_header Set-Cookie "csrftoken=resetmit; Domain=.mit.edu; Expires=1/January/2019 00:00:00";
    - after: P3P*

reload_nginx_config
  service.running:
    - name: nginx
    - reload: True
    - onchanges:
        - file: update_max_upload_for_lms
        - file: set_expired_csrf_token_for_lms

{% if 'edx-base-worker' not in salt.grains.get('roles') %}
{% if 'edx-worker' in salt.grains.get('roles') and not 'qa' in salt.grains.get('environment') %}
restart_edx_worker_service:
  supervisord.running:
    - name: all
    - restart: True
    - bin_env: '/edx/bin/supervisorctl'
    - onchanges:
      - file: place_ansible_environment_configuration
    - require:
      - cmd: run_ansible
{% endif %}
{% endif %}

{% if 'edx-analytics' in salt.grains.get('roles') %}
stop_edxapp_services:
  supervisord.dead:
    - name: all
    - bin_env: '/edx/bin/supervisorctl'
    - require:
      - cmd: run_ansible

stop_nginx_service:
  service.dead:
    - name: nginx
    - enable: False
{% endif %}
