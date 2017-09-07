{% from 'devstack.sls' import admin_mysql_username, admin_mysql_password, MYSQL_HOST,
  edxapp_mysql_username, edxapp_mysql_password with context %}

mysql:
  server:
    root_user: {{ admin_mysql_username }}
    root_password: {{ admin_mysql_password }}
    mysql_host: 0.0.0.0
    mysqld:
      bind-address: 0.0.0.0

  database:
    - xqueue_devstack
    - edxapp_devstack
    - edxapp_csmh

  user:
    {{ admin_mysql_username }}:
      password: {{ admin_mysql_username }}
      host: {{ MYSQL_HOST }}
      databases:
        - database: xqueue_devstack
          grants: ['all privileges']
        - database: edxapp_devstack
          grants: ['all privileges']
        - database: edxapp_csmh
          grants: ['all privileges']
    {{ edxapp_mysql_username }}:
      password: {{ edxapp_mysql_password }}
      host: {{ MYSQL_HOST }}
      databases:
        - database: xqueue_devstack
          grants: ['all privileges']
        - database: edxapp_devstack
          grants: ['all privileges']
        - database: edxapp_csmh
          grants: ['all privileges']
