{% set data_path = '/tmp/edx_config' -%}
{% set venv_path = '/tmp/edx_config/venv' -%}
{% set repo_path = '/tmp/edx_config/configuration' -%}
{% set conf_file = '/tmp/edx_config/edx-xqwatcher.conf' -%}
{% set playbooks = salt.pillar.get('xqueue:playbooks', ['edx-east/xqwatcher.yml']) %}

configure_git_ppa_for_edx:
  pkgrepo.managed:
    - ppa: git-core/ppa
    - require_in:
        - pkg: install_os_packages

install_os_packages:
  pkg.installed:
    - pkgs:
        - git
        - python
        - python-dev
        - python3
        - python3-dev
        - python-pip
        - python-virtualenv
        - libmysqlclient-dev
        - libssl-dev
    - refresh: True
    - refresh_modules: True

clone_edx_configuration:
  file.directory:
    - name: {{ repo_path }}
    - makedirs: True
  git.latest:
    - name: {{ salt.pillar.get('edx:config:repo', 'https://github.com/edx/configuration.git') }}
    - rev: {{ salt.pillar.get('edx:config:branch', 'open-release/eucalyptus.2') }}
    - target: {{ repo_path }}
    - user: root
    - force_checkout: True
    - force_clone: True
    - force_reset: True
    - force_fetch: True
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

place_ansible_environment_configuration:
  file.managed:
    - name: {{ conf_file }}
    - contents: |
        {{ salt.pillar.get('xqwatcher') | yaml(False) |indent(8) }}
    - makedirs: True

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

activate_xqwatcher_supervisor_config:
  file.symlink:
    - name: /edx/app/supervisor/conf.d/xqwatcher.conf
    - target: /edx/app/supervisor/conf.available.d/xqwatcher.conf
    - user: supervisor
    - group: www-data
  cmd.wait:
    - name: /edx/bin/supervisorctl reread && /edx/bin/supervisorctl update
    - watch:
        - file: activate_xqwatcher_supervisor_config
