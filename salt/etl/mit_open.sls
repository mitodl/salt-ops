{% set settings = salt.pillar.get('etl_config', {}) %}
mit_open_etl_config:
  file.managed:
    - name: /odl-etl/mit-open/etl_settings.yml
    - contents: |
        {{ settings|yaml(False)|indent(8) }}
    - makedirs: True

add_task_to_cron:
  cron.present:
    - name: '/odl-etl/mit-open/bin/python3 /odl-etl/mit-open/email_mapping.py'
    - comment: mit_open_etl_script
    - special: '@daily'
    - require:
      - file: mit_open_etl_config
