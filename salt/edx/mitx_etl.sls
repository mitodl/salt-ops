install_etl_os_dependencies:
  pkg.installed:
    - pkgs:
        - python3
        - python3-pip
        - git
        - awscli
    - refresh: True

create_mitx_directory:
  file.directory:
    - name: /odl-etl

clone_mitx_etl_repo:
  git.latest:
    - name: https://github.com/mitodl/odl-etl
    - target: /odl-etl/
    - force_clone: True
    - force_reset: True
    - require:
      - pkg: install_etl_os_dependencies
      - file: create_mitx_directory

install_mitx_residential_etl_requirements:
  virtualenv.managed:
    - name: /odl-etl/mitx_etl
    - system_site_packages: False
    - requirements: /odl-etl/mitx/requirements.txt
    - python: /usr/bin/python3
    - env_vars:
        PATH_VAR: '/usr/local/bin/pip3'
    - require:
      - git: clone_mitx_etl_repo
      - pkg: install_etl_os_dependencies

{% set settings = salt.pillar.get('mitx_residential_etl:settings', {}) %}
mitx_residential_etl_config:
  file.managed:
    - name: /odl-etl/mitx/settings.json
    - contents: |
        {{ settings|json(indent=2, sort_keys=True) |indent(8) }}
    - require:
      - git: clone_mitx_etl_repo

add_task_to_cron:
  cron.present:
    - name: '/odl-etl/mitx_etl/bin/python3 /odl-etl/mitx/mitx_residential_etl.py'
    - comment: mitx_residential_etl_script
    - special: '@daily'
    - require:
      - file: mitx_residential_etl_config
