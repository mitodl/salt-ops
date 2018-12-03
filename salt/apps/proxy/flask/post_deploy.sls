{% set app_name = salt.pillar.read{'heroku:app_name'} %}
{% set user = salt.pillar.read('django:user') %}
{% set group = salt.pillar.read('django:group') %}
{% set directory = '/opt/{}'.format(app_name) %}
{% set service = 'flask_{}'.format(app_name) %}

create_{{ service }}_definition:
  file.managed:
    - name: /etc/systemd/system/{{ service }}.service
    - source: salt://apps/templates/flask.service
    - template: jinja
    - context:
        service: {{ service }}
        directory: {{ directory }}
        user: {{ user }}
        group: {{ group }}
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: /etc/systemd/system/{{ service }}.service

enable_service_{{ service }}:
  service.running:
    - name: {{ service }}
    - enable: True
    - require:
      - file: deploy_systemd_for_{{ service }}
