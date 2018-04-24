#!jinja|yaml|gpg

{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set duplicity_passphrase = salt.vault.read('secret-operations/global/duplicity-passphrase').data.value %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}
{% set env_data = env_settings.environments[environment] %}
{% set edxapp_mysql_creds = salt.vault.read('mysql-{}/creds/admin'.format(environment)) %}
{% set edxapp_mongodb_creds = salt.vault.read('mongodb-{}/creds/admin'.format(environment)) %}
{% if environment == 'mitx-qa' %}
{% set efs_id = 'fs-6f55af26' %}
{% elif environment == 'mitx-production' %}
{% set efs_id = 'fs-1f27ae56' %}
{% endif %}
{% set purpose_list = [] %}
{% set mongo_map = {} %}
{% set db_prefixes = [
    'contentstore',
    'modulestore',
    'gitlog',
    'forum',
] %}
restores:
{% for purpose, purpose_data in env_data.purposes.items() %}
{% if 'live' in purpose or 'draft' in purpose %}
{% do purpose_list.append(purpose) %}
  - title: mysql-{{ purpose }}-{{ environment }}
    name: mysql
    pkgs:
      - mydumper
    settings:
      host: mysql.service.consul
      port: 3306
      threads: 10
      password: {{ edxapp_mysql_creds.data.password }}
      username: {{ edxapp_mysql_creds.data.username }}
      duplicity_passphrase: {{ duplicity_passphrase }}
      {% if 'draft' in purpose %}
      directory: mysql-mitx-production-residential-draft
      {% set mysql_map = {
          'edxapp_residential_draft': 'edxapp_{}'.format(purpose.replace('-', '_'))} %}
      {% elif 'live' in purpose %}
      {% set mysql_map = {
          'edxapp_residential_live': 'edxapp_{}'.format(purpose.replace('-', '_'))} %}
      directory: mysql-mitx-production-residential-live
      {% endif %}
      {% for key,value in mysql_map.items() %}
      restore_to: {{ value }}
      restore_from: {{ key }}
      {% endfor %}
{% for db in db_prefixes %}
{% if 'live' in purpose %}
{% set suffix = 'live' %}
{% else %}
{% set suffix = 'draft' %}
{% endif %}
{% set map_key = '{}_{}'.format(db, purpose.replace('-', '_')) %}
{% do mongo_map.update({map_key: '{}_residential_{}'.format(db, suffix)}) %}
{% endfor %}
  - title: mongodb-{{ environment }}-{{ purpose }}
    name: mongodb
    pkgs:
      - mongodb-clients
    settings:
      host: mongodb-master.service.consul
      port: 27017
      password: {{ edxapp_mongodb_creds.data.password }}
      username: {{ edxapp_mongodb_creds.data.username }}
      duplicity_passphrase: {{ duplicity_passphrase }}
      directory: mongodb-mitx-production
      db_map: {{ mongo_map }}
{% endif %}
{% endfor %}
  - title: live_course_assets
    name: course_assets
    pkgs:
      - curl
      - nfs-common
    settings:
      duplicity_passphrase: {{ duplicity_passphrase }}
      efs_id: {{ efs_id }}
      directory: prod_repos
  - title: draft_course_assets
    name: course_assets
    pkgs:
      - curl
      - nfs-common
    settings:
      duplicity_passphrase: {{ duplicity_passphrase }}
      efs_id: {{ efs_id }}
      directory: repos
