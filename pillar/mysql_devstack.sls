{% from 'pillar/devstack.sls' import COMMON_MYSQL_ADMIN_USER, COMMON_MYSQL_ADMIN_PASS, MYSQL_HOST,
XQUEUE_MYSQL_DB_NAME, EDXAPP_MYSQL_DB_NAME, COMMON_MYSQL_MIGRATE_USER, COMMON_MYSQL_MIGRATE_PASS,
XQUEUE_MYSQL_USER, XQUEUE_MYSQL_PASSWORD, EDXAPP_MYSQL_USER, EDXAPP_MYSQL_PASSWORD with context %}

mysql:
  server:
    root_user: {{ COMMON_MYSQL_ADMIN_USER }}
    root_password: {{ COMMON_MYSQL_ADMIN_PASS }}
    mysql_host: {{ MYSQL_HOST }}

  database:
    - {{ XQUEUE_MYSQL_DB_NAME }}
    - {{ EDXAPP_MYSQL_DB_NAME }}

  user:
    {{ COMMON_MYSQL_MIGRATE_USER }}:
      password: {{ COMMON_MYSQL_MIGRATE_PASS }}
      host: {{ MYSQL_HOST }}
      databases:
        - database: {{ XQUEUE_MYSQL_DB_NAME }}
          grants: ['all privileges']
        - database: {{ EDXAPP_MYSQL_DB_NAME }}
          grants: ['all privileges']
    {{ XQUEUE_MYSQL_USER }}:
      password: {{ XQUEUE_MYSQL_PASSWORD }}
      host: {{ MYSQL_HOST }}
      databases:
        - database: {{ XQUEUE_MYSQL_DB_NAME }}
          grants: ['all privileges']
    {{ EDXAPP_MYSQL_USER }}:
      password: {{ EDXAPP_MYSQL_PASSWORD }}
      host: {{ MYSQL_HOST }}
      databases:
        - database: {{ EDXAPP_MYSQL_DB_NAME }}
          grants: ['all privileges']
