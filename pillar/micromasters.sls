{% set rds_credentials = salt.vault.read('secret-micromasters/production/rds-credentials') %}
{% set database_credentials = salt.vault.read('secret-micromasters/production/database-credentials') %}

micromasters:
  db:
    master_user: {{ rds_credentials.data.username }}
    master_password: {{ rds_credentials.data.password }}
    port: 15432
    app_db: micromasters
    app_user: {{ database_credentials.data.username }}
    app_password: {{ database_credentials.data.password }}
