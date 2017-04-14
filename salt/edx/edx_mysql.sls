#!jinja|yaml

{% from "orchestrate/aws_env_macro.jinja" import ENVIRONMENT with context %}
{% set environment = salt.pillar.get('environments:{}'.format(ENVIRONMENT)) %}
{% set purposes = environment.purposes %}
{% set edxlocal_databases = {
  'XQUEUE_MYSQL_DB_NAME': 'xqueue',
  'EDXAPP_MYSQL_DB_NAME': 'edxapp',
  }
%}
{% set edxapp_mysql_creds = salt.vault.read(
    'mysql-{env}/creds/edxapp-{purpose}'.format(
        env=environment,
        purpose=purpose)) %}
{% set edxapp_mysql_host = salt.pillar.get('edx:ansible_vars:EDXAPP_MYSQL_HOST') %}
{% set edxapp_mysql_port = salt.pillar.get('edx:ansible_vars:EDXAPP_MYSQL_PORT') %}

{% for db,name in edxlocal_databases.iteritems() %}
{% for purpose in purposes %}
edxapp_create_db_{{ name }}-{{ purpose }}:
  mysql_database.present:
    - name: {{ name }}-{{ purpose }}
    - connection_user: {{ edxapp_mysql_creds.data.username }}
    - connection_pass: {{ edxapp_mysql_creds.data.password }}
    - connection_args:
        mysql.host: {{ edxapp_mysql_host }}
        mysql.port: {{ edxapp_mysql_port }}
{% endfor %}
{% endfor %}
