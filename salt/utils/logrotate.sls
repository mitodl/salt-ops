{% set logrotate_files = salt.pillar.get('logrotate') %}
{% for name, settings in logrotate_files.items() %}

generate_{{ name }}_logrotate:
  file.managed:
    - name: /etc/logrotate.d/{{ name }}
    - source: salt://utils/logrotate/conf.jinja
    - template: jinja
    - mode: '0644'
    - context:
        settings: {{ settings }}
{% endfor %}
