{% set etl_configs = salt.pillar.get('etl:configs', {}) %}
{% set task_name = 'email_mapping' %}
{% for app_name, settings in etl_configs.items() %}
{{ app_name }}_{{ task_name }}_etl_config:
  file.managed:
    - name: /odl-etl/{{ task_name }}/{{ app_name }}_settings.yml
    - contents: |
        {{ settings|yaml(False)|indent(8) }}
    - makedirs: True

add_{{ app_name }}_task_to_cron:
  cron.present:
    - name: '/odl-etl/{{ task_name }}/bin/python3 /odl-etl/{{ task_name }}/email_mapping.py {{ app_name}}'
    - comment: {{ app_name }}_etl_script
    - special: '@daily'
    - require:
      - file: {{ app_name }}_{{ task_name }}_etl_config
{% endfor %}
