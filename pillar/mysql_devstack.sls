{% from 'devstack.sls' import admin_mysql_username, admin_mysql_password, MYSQL_HOST,
  xqueue_mysql_username, xqueue_mysql_password, edxapp_mysql_username, edxapp_mysql_password with context %}

mysql:
  server:
    root_user: {{ admin_mysql_username }}
    root_password: {{ admin_mysql_password }}
    mysql_host: {{ MYSQL_HOST }}

  database:
    - xqueue_devstack
    - edxapp_devstack

  user:
    {{ admin_mysql_username }}:
      password: {{ admin_mysql_username }}
      host: {{ MYSQL_HOST }}
      databases:
        - database: xqueue_devstack
          grants: ['all privileges']
        - database: edxapp_devstack
          grants: ['all privileges']
    {{ xqueue_mysql_username }}:
      password: {{ xqueue_mysql_password }}
      host: 'localhost', {{ MYSQL_HOST }}
      databases:
        - database: xqueue_devstack
          grants: ['all privileges']
    {{ edxapp_mysql_username }}:
      password: {{ edxapp_mysql_password }}
      host: 'localhost', {{ MYSQL_HOST }}
      databases:
        - database: edxapp_devstack
          grants: ['all privileges']
