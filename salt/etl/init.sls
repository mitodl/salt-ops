{% set task_name = salt.pillar.get('etl_config:task_name') %}

install_etl_os_dependencies:
  pkg.installed:
    - pkgs: {{ salt.pillar.get('etl_dependencies', ['python3', 'python3-pip', 'git'])|tojson }}
    - refresh: True

create_etl_directory:
  file.directory:
    - name: /odl-etl

clone_odl_etl_repo:
  git.latest:
    - name: https://github.com/mitodl/odl-etl
    - target: /odl-etl/
    - force_clone: True
    - force_reset: True
    - require:
      - pkg: install_etl_os_dependencies
      - file: create_etl_directory

install_etl_requirements:
  virtualenv.managed:
    - name: /odl-etl/{{ task_name }}
    - system_site_packages: False
    - requirements: /odl-etl/{{ task_name }}/requirements.txt
    - python: /usr/bin/python3
    - env_vars:
        PATH_VAR: '/usr/local/bin/pip3'
    - require:
      - git: clone_odl_etl_repo
      - pkg: install_etl_os_dependencies
