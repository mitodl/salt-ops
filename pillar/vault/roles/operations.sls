{% set SIX_MONTHS = '4368h' %}
vault:
  roles:
    admin-mysql-operations-techtv:
      backend: mariadb-operations-techtvcopy
      name: admin
      options:
        db_name: techtvcopy
        default_ttl: {{ SIX_MONTHS }}
        max_ttl: {{ SIX_MONTHS }}
        creation_statements: {% raw %}"CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT ALL ON `%`.* TO '{{name}}'@'%';"{% endraw %}
        revocation_statements: {% raw %}"DROP USER '{{name}}';"{% endraw %}
    readonly-mysql-operations-techtv:
      backend: mariadb-operations-techtvcopy
      name: readonly
      options:
        db_name: techtvcopy
        default_ttl: {{ SIX_MONTHS }}
        max_ttl: {{ SIX_MONTHS }}
        creation_statements: {% raw %}"CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT, SHOW VIEW ON `%`.* TO '{{name}}'@'%';"{% endraw %}
        revocation_statements: {% raw %}"DROP USER '{{name}}';"{% endraw %}
