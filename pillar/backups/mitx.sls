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

backups:
  enabled:
  {% for purpose, purpose_data in env_data.purposes.items() %}
  {% if purpose_data.business_unit == 'residential' %}
    - title: mysql-edxapp-{{ purpose }}
      name: mysql
      pkgs:
        - mydumper
      settings:
        host: mysql.service.consul
        port: 3306
        password: {{ edxapp_mysql_creds.data.password }}
        username: {{ edxapp_mysql_creds.data.username }}
        directory: mysql-{{ environment }}-{{ purpose }}
        database: edxapp_{{ purpose|replace('-', '_') }}
        duplicity_passphrase: {{ duplicity_passphrase }}
  {% endif %}
  {% endfor %}
    - title: mongodb-{{ environment }}
      name: mongodb
      pkgs:
        - mongodb-clients
      settings:
        host: mongodb-master.service.consul
        port: 27017
        username: {{ edxapp_mongodb_creds.data.username }}
        password: {{ edxapp_mongodb_creds.data.password }}
        duplicity_passphrase: {{ duplicity_passphrase }}
        directory: mongodb-{{ environment }}
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
