#!jinja|yaml|vault

edx:
  ansible_vars:
    ### COMMON VARS ###
    COMMON_MYSQL_ADMIN_USER: vault['mysql-mitx-qa/creds/admin'].data.username
    COMMON_MYSQL_ADMIN_PASS: vault['mysql-mitx-qa/creds/admin'].data.password
    COMMON_MYSQL_MIGRATE_USER: vault['mysql-mitx-qa/creds/edxapp'].data.username
    COMMON_MYSQL_MIGRATE_PASS: vault['mysql-mitx-qa/creds/edxapp'].data.username
