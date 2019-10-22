include:
  - mongodb.repository

{% set settings = salt.pillar.get('mitx_etl:settings', {}) %}

mitx_etl_config:
  file.managed:
    - name: /odl-etl/mitx/settings.json
    - contents: |
        {{ settings|json(indent=2, sort_keys=True) |indent(8) }}
    - makedirs: True

add_task_to_cron:
  cron.present:
    - name: '/odl-etl/mitx/bin/python3 /odl-etl/mitx/mitx_etl.py'
    - comment: mitx_etl_script
    - special: '@daily'
    - require:
      - file: mitx_etl_config

install_mongodb_client_for_dumping_data:
  pkg.installed:
    - name: mongodb-clients
    - refresh: True
    - require:
      - pkgrepo: add_mongodb_package_repository
