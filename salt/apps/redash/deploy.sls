migrate_redash_database:
  cmd.run:
    - name: /opt/redash/bin/run ./manage.py db upgrade
    - cwd: /opt/redash
    - runas: redash
    - require:
        - archive: deploy_application_source_to_destination
        - pip: install_python_requirements
        - pip: install_python_requirements_for_all_datasources

create_env_file_for_redash:
  file.managed:
    - name: /opt/{{ salt.pillar.get('django:app_name') }}/.env
    - contents: |
        {%- for var, val in salt.pillar.get('django:environment').items() %}
        {{ var }}={{ val }}
        {%- endfor %}
    - require:
        - archive: deploy_application_source_to_destination
