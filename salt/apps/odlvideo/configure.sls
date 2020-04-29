include:
    - uwsgi.service
    - apps.odlvideo.deploy_signal

create_env_file_for_odlvideo:
  file.managed:
    - name: /opt/{{ salt.pillar.get('django:app_name') }}/.env
    - contents: |
        {%- for var, val in salt.pillar.get('django:environment').items() %}
        {{ var }}={{ val }}
        {%- endfor %}
    - onchanges_in:
        - service: uwsgi_service_running
        - file: signal_odlvideo_deploy_complete

ensure_perms_of_odlvideo_app_log:
  file.managed:
    - name: /var/log/odl-video-service.log
    - user: deploy
    - group: deploy
    - mode: 0644
    - onchanges_in:
        - service: uwsgi_service_running
