{% set app_dir = '/opt/{0}'.format(salt.pillar.get('django:app_name')) %}

include:
  - uwsgi.service

write_app_config_overrides:
  file.managed:
    - name: {{ app_dir }}/StarCellBio/settings.yml
    - contents: |
        {{ salt.pillar.get('starcellbio', {})|yaml(False)|indent(8) }}
    - user: deploy
    - onchanges_in:
        - service: uwsgi_service_running
