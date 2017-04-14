#!jinja|yaml
{% from "shared/edx/mitx.jinja" import edx with context %}
{% set purposes = salt.grains.get('purpose') %}
{% set edxlocal_databases = {
  'XQUEUE_MYSQL_DB_NAME': 'xqueue',
  'EDXAPP_MYSQL_DB_NAME': 'edxapp',
  }
%}
{% set mysql_user = salt.pillar.get('edx:ansible_vars:EDXAPP_MYSQL_USER') %}
{% set mysql_password = salt.pillar.get('edx:ansible_vars:EDXAPP_MYSQL_PASSWORD') %}

{% for db,name in edxlocal_databases.iteritems() %}
{% for purpose in purposes %}
edxapp_create_db_{{ name }}-{{ purpose }}:
  mysql_database.present:
    - name: {{ name }}-{{ purpose }}
    - connection_user: {{ mysql_user }}
    - connection_pass: {{ mysql_password }}
{% endfor %}
{% endfor %}
