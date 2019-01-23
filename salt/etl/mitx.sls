{% set settings = salt.pillar.get('mitx_residential_etl:settings', {}) %}
mitx_residential_etl_config:
  file.managed:
    - name: /odl-etl/mitx/settings.json
    - contents: |
        {{ settings|json(indent=2, sort_keys=True) |indent(8) }}
    - makedirs: True

add_task_to_cron:
  cron.present:
    - name: '/odl-etl/mitx_etl/bin/python3 /odl-etl/mitx/mitx_residential_etl.py'
    - comment: mitx_residential_etl_script
    - special: '@daily'
    - require:
      - file: mitx_residential_etl_config
