#!jinja|yaml

{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT') %}
{% set environment = salt.pillar.get('environments:{}'.format(ENVIRONMENT)) %}
{% set purposes = environment.purposes %}

{% set postgresql_host = 'postgresql.service.{}.consul'.format(ENVIRONMENT) %}
{% set postgresql_port = 5432 %}
{% set postgresql_creds = salt.vault.read(
    'postgresql-{env}/creds/admin'.format(
        env=ENVIRONMENT)) %}

{% for schema in environment.backends.postgres_rds.schemas %}
create_db_{{ schema }}:
  postgres_database.present:
    - name: {{ schema }}
    - encoding: utf8
    - db_user: {{ postgresql_creds.data.username }}
    - db_password: {{ postgresql_creds.data.password }}
    - db_host: {{ postgresql_host }}
    - db_port: {{ postgresql_port }}
{% endfor %}
