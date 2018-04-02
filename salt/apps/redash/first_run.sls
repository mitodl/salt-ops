{% set redash_env = salt.pillar.get('django:environment') %}
{% set root_user = salt.pillar.get('redash:root_user') %}

create_redash_database_tables:
  cmd.run:
    - name: /opt/redash/bin/run ./manage.py database create_tables
    - cwd: /opt/redash
    - runas: redash
    - env: {{ redash_env }}

create_redash_root_user:
  cmd.run:
    - name: /opt/redash/bin/run ./manage.py users create_root --password {{ root_user.password }} {{ root_user.email }} {{ root_user.name }}
    - cwd: /opt/redash
    - runas: redash
    - env: {{ redash_env }}
