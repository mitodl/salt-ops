#!jinja|yaml

{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT') %}
{% set environment = salt.pillar.get('environments:{}'.format(ENVIRONMENT)) %}
{% set purposes = environment.purposes %}

{% for dbconfig in environment.backends.rds %}
{% if dbconfig.engine == 'postgres' %}
{% set postgresql_host = 'postgres-{}.service.{}.consul'.format(dbconfig.name, ENVIRONMENT) %}
{% set postgresql_port = 5432 %}
{% set postgresql_creds = salt.vault.read(
    '{engine}-{env}-{dbname}/creds/admin'.format(
        engine=dbconfig.engine, env=ENVIRONMENT, dbname=dbconfig.name)) %}

create_db_app_role_{{ dbconfig.name }}:
  postgres_group.present:
    - name: {{ dbconfig.name }}
    - createdb: False
    - createroles: False
    - createuser: False
    - login: False
    - superuser: False
    - inherit: False
    - refresh_password: True
    - db_user: {{ postgresql_creds.data.username }}
    - db_password: {{ postgresql_creds.data.password }}
    - db_host: {{ postgresql_host }}
    - db_port: {{ postgresql_port }}

add_master_user_to_app_role_in_{{ dbconfig.name }}:
  postgres_privileges.present:
    - name: odldevops
    - object_name: {{ dbconfig.name }}
    - object_type: group
    - db_user: {{ postgresql_creds.data.username }}
    - db_password: {{ postgresql_creds.data.password }}
    - db_host: {{ postgresql_host }}
    - db_port: {{ postgresql_port }}

{% for object_type in ['table', 'sequence'] %}
grant_all_on_{{ object_type }}_for_{{ dbconfig.name }}:
  postgres_privileges.present:
    - name: {{ dbconfig.name }}
    - object_name: ALL
    - object_type: {{ object_type }}
    - privileges:
        - ALL
    - grant_option: True
    - maintenance_db: {{ dbconfig.name }}
    - db_user: {{ postgresql_creds.data.username }}
    - db_password: {{ postgresql_creds.data.password }}
    - db_host: {{ postgresql_host }}
    - db_port: {{ postgresql_port }}
{% endfor %}

{% for schema in dbconfig.get('schemas', []) %}
create_db_{{ schema }}:
  postgres_database.present:
    - name: {{ schema }}
    - encoding: utf8
    - owner: odldevops
    - db_user: {{ postgresql_creds.data.username }}
    - db_password: {{ postgresql_creds.data.password }}
    - db_host: {{ postgresql_host }}
    - db_port: {{ postgresql_port }}
{% endfor %}
{% endif %}
{% endfor %}
