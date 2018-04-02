{% set app_name = 'redash' %}
{% set ENVIRONMENT = salt.grains.get('environment', 'operations') %}
{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set purpose_data = env_data.purposes[app_name] %}
{% set root_user = salt.vault.read('secret-' ~ purpose_data.business_unit ~ '/' ~ ENVIRONMENT ~ '/' ~ app_name ~ '/root-user').data %}
{% set redash_env = salt.pillar.get('django:environment') %}

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
