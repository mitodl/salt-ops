include:
    - uwsgi.service

create_env_file_for_odlvideo:
  file.managed:
    - name: /opt/{{ salt.pillar.get('django:app_name') }}/.env
    - contents: |
        {%- for var, val in salt.pillar.get('django:environment').items() %}
        {{ var }}={{ val }}
        {%- endfor %}
    - require:
        - deploy_application_source_to_destination
    - onchanges_in:
        - service: uwsgi_service_running
