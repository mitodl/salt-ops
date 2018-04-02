{% set redash_env = salt.pillar.get('django:environment') %}
{% set root_user = salt.pillar.get('redash:root_user') %}

migrate_redash_database:
  cmd.run:
    - name: /opt/redash/bin/run ./manage.py database create_tables
    - cwd: /opt/redash
    - runas: redash
    - env: {{ redash_env }}
    - require:
        - archive: deploy_application_source_to_destination
        - pip: install_python_requirements
        - pip: install_python_requirements_for_all_datasources

migrate_redash_database:
  cmd.run:
    - name: /opt/redash/bin/run ./manage.py users --password {{ root_user.password }} {{ root_user.email }} {{ root_user.name }}
    - cwd: /opt/redash
    - runas: redash
    - env: {{ redash_env }}
    - require:
        - archive: deploy_application_source_to_destination
        - pip: install_python_requirements
        - pip: install_python_requirements_for_all_datasources
