#!jinja|yaml|gpg

{% set env_settings = salt.file.read(salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml"))|load_yaml %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}
{% set env_data = env_settings.environments[environment] %}
{% set duplicity_passphrase = '__vault__::secret-operations/global/duplicity-passphrase>data>value' %}
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
        threads: 10
        password: __vault__:cache:mysql-{{ environment }}/creds/admin>data>password
        username: __vault__:cache:mysql-{{ environment }}/creds/admin>data>username
        directory: mysql-{{ environment }}-{{ purpose }}
        database: edxapp_{{ purpose|replace('-', '_') }}
        duplicity_passphrase: {{ duplicity_passphrase }}
        healthcheck_url: __vault__::secret-operations/global/healthchecks/mitx-backups-mysql-{{ purpose }}>data>value
  {% endif %}
  {% endfor %}
    - title: mongodb-{{ environment }}
      name: mongodb
      pkgs:
        - mongodb-clients
      settings:
        host: mongodb-master.service.consul
        port: 27017
        username: __vault__:cache:mongodb-{{ environment }}/creds/admin>data>username
        password: __vault__:cache:mongodb-{{ environment }}/creds/admin>data>password
        duplicity_passphrase: {{ duplicity_passphrase }}
        directory: mongodb-{{ environment }}
        healthcheck_url: __vault__::secret-operations/global/healthchecks/mitx-backups-mongodb>data>value
    - title: live_course_assets
      name: course_assets
      pkgs:
        - curl
        - nfs-common
      settings:
        duplicity_passphrase: {{ duplicity_passphrase }}
        efs_id: {{ efs_id }}
        directory: prod_repos
        healthcheck_url: __vault__::secret-operations/global/healthchecks/mitx-backups-course-assets-residential-live>data>value
    - title: draft_course_assets
      name: course_assets
      pkgs:
        - curl
        - nfs-common
      settings:
        duplicity_passphrase: {{ duplicity_passphrase }}
        efs_id: {{ efs_id }}
        directory: repos
        healthcheck_url: __vault__::secret-operations/global/healthchecks/mitx-backups-course-assets-residential-draft>data>value
