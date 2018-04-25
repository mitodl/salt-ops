#!jinja|yaml

{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT') %}
{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set environment = salt.pillar.get('environments:{}'.format(ENVIRONMENT)) %}
{% set purposes = environment.purposes %}

{% set edxapp_mysql_host = 'mysql.service.{}.consul'.format(ENVIRONMENT) %}
{% set edxapp_mysql_port = 3306 %}
{% set edxapp_mysql_creds = salt.vault.read(
    'mysql-{env}/creds/admin'.format(
        env=ENVIRONMENT)) %}

{% for name in env_settings.edxapp_secret_backends.mysql.role_prefixes %}
{% for purpose in purposes %}
edxapp_create_db_{{ name }}_{{ purpose }}:
  mysql_database.present:
    - name: {{ name|replace('-', '_') }}_{{ purpose|replace('-', '_') }}
    - connection_user: {{ edxapp_mysql_creds.data.username }}
    - connection_pass: {{ edxapp_mysql_creds.data.password }}
    - connection_host: {{ edxapp_mysql_host }}
    - connection_port: {{ edxapp_mysql_port }}
{% endfor %}
{% endfor %}
