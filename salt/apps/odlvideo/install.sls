mange_presence_and_permissions_for_source_code_directory:
  file.directory:
    - name: /opt/{{ salt.pillar.get('django:app_name') }}
    - makedirs: True
    - user: {{ salt.pillar.get('django:user', 'deploy') }}
    - group: {{ salt.pillar.get('django:user', 'deploy') }}
    - require_in:
        - deploy_application_source_to_destination

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
