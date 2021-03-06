{% set data_path = '/tmp/edx_config' -%}
{% set venv_path = '/tmp/edx_config/venv' -%}
{% set repo_path = '/tmp/edx_config/configuration' -%}
{% set conf_file = '/tmp/edx_config/edx-xqwatcher.conf' -%}
{% set playbooks = salt.pillar.get('xqueue:playbooks', ['edx-east/xqwatcher.yml']) %}
{% set python3_version = 'python3.8' %}
{% set pip_version = 'pip3.8' %}

include:
  - .run_ansible

configure_git_ppa_for_edx:
  pkgrepo.managed:
    - ppa: git-core/ppa
    - require_in:
        - pkg: install_os_packages_for_xqwatcher

configure_python_ppa:
  pkgrepo.managed:
    - ppa: deadsnakes/ppa
    - require_in:
        - pkg: install_os_packages_for_xqwatcher

install_os_packages_for_xqwatcher:
  pkg.installed:
    - pkgs:
        - git
        - python3
        - python3-dev
        - python3-pip
        - python3-virtualenv
        - libmariadb-dev
        - libmariadb-dev-compat
        - libssl-dev
        - libopenblas-dev
        - liblapack-dev
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

set_directory_permissions_for_xqwatcher_logs:
  file.directory:
    - name: /edx/var/log/xqwatcher
    - user: www-data
    - group: xqwatcher
    - recurse:
        - user
        - group

{% for course in salt.pillar.get('edx:ansible_vars:XQWATCHER_COURSES', []) %}
ensure_codejail_requirements_are_installed_for_{{  course.COURSE }}:
  pip.installed:
    - requirements: /edx/app/xqwatcher/data/{{ course.QUEUE_CONFIG.HANDLERS[0].CODEJAIL.name }}-requirements.txt
    - bin_env: /edx/app/xqwatcher/venvs/{{ course.QUEUE_CONFIG.HANDLERS[0].CODEJAIL.name }}/bin/{{ pip_version }}
    - env_vars:
        HOME: /tmp
        USER: {{ course.QUEUE_CONFIG.HANDLERS[0].CODEJAIL.user }}
{% endfor %}

{% if salt.pillar.get('edx:xqwatcher:grader_requirements') %}
ensure_grader_requirements_are_installed:
  pip.installed:
    - pkgs: {{ salt.pillar.get('edx:xqwatcher:grader_requirements') }}
    - bin_env: /edx/app/xqwatcher/venvs/xqwatcher/bin/pip
{% endif %}
