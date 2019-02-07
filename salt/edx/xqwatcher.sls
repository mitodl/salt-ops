{% set data_path = '/tmp/edx_config' -%}
{% set venv_path = '/tmp/edx_config/venv' -%}
{% set repo_path = '/tmp/edx_config/configuration' -%}
{% set conf_file = '/tmp/edx_config/edx-xqwatcher.conf' -%}
{% set playbooks = salt.pillar.get('xqueue:playbooks', ['edx-east/xqwatcher.yml']) %}

include:
  - .run_ansible

configure_git_ppa_for_edx:
  pkgrepo.managed:
    - ppa: git-core/ppa
    - require_in:
        - pkg: install_os_packages_for_xqwatcher

install_os_packages_for_xqwatcher:
  pkg.installed:
    - pkgs:
        - git
        - python
        - python-dev
        - python3
        - python3-dev
        - python-pip
        - python3-pip
        - python-virtualenv
        - python3-virtualenv
        - libmysqlclient-dev
        - libssl-dev
    - refresh: True
    - refresh_modules: True
    - require_in:
        - virtualenv: create_ansible_virtualenv
        - git: clone_edx_configuration
        - cmd: run_ansible

link_venv_binary_to_expected_location:
  file.symlink:
    - name: /usr/local/bin/virtualenv
    - target: /usr/bin/virtualenv
    - require:
        - pkg: install_os_packages_for_xqwatcher
    - require_in:
        - cmd: run_ansible

activate_xqwatcher_supervisor_config:
  file.symlink:
    - name: /edx/app/supervisor/conf.d/xqwatcher.conf
    - target: /edx/app/supervisor/conf.available.d/xqwatcher.conf
    - user: supervisor
    - group: www-data
    - require:
        - cmd: run_ansible
  cmd.wait:
    - name: /edx/bin/supervisorctl reread && /edx/bin/supervisorctl update
    - watch:
        - file: activate_xqwatcher_supervisor_config

configure_logging_for_xqwatcher:
  file.managed:
    - name: /edx/app/xqwatcher/logging.json
    - contents: |
        {{ salt.pillar.get('edx:xqwatcher:logconfig', {})|json(indent=2)|indent(8) }}

{% for course in salt.pillar.get('edx:ansible_vars:XQWATCHER_COURSES', []) %}
ensure_codejail_requirements_are_installed_for_{{  course.COURSE }}:
  pip.installed:
    - requirements: /edx/app/xqwatcher/data/{{ course.QUEUE_CONFIG.HANDLERS[0].CODEJAIL.name }}-requirements.txt
    - bin_env: /edx/app/xqwatcher/venvs/mit-600x/
{% endfor %}
