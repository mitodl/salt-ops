#!jinja|yaml
{% from "shared/edx/mitx.jinja" import edx with context %}

{% set purposes = salt.grains.get('purpose') %}

{% set edxlocal_databases = {
  'XQUEUE_MYSQL_DB_NAME': 'xqueue',
  'EDXAPP_MYSQL_DB_NAME': 'edxapp',
  }
%}

{% for db,name in edxlocal_databases.iteritems() %}
{% for purpose in purposes %}
edxapp_create_db_{{ name }}-{{ purpose }}:
  mysql_database.present:
    - name: {{ name }}-{{ purpose }}
    - connection_user: {{ edx.edxapp_mysql_database_user }}
    - connection_pass: {{ edx.edxapp_mysql_password }}
{% endfor %}
{% endfor %}
