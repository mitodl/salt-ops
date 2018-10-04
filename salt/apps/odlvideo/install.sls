include:
    - uwsgi.service

ensure_yarn_is_installed_for_odlvideo:
  npm.installed:
    - name: 'yarn@1.2.1'
    - user: root

install_node_dependencies:
  cmd.run:
    - name: yarn install
    - cwd: /opt/{{ salt.pillar.get('django:app_name') }}
    - require:
        - deploy_application_source_to_destination

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