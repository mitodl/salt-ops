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
    postgresql_redash_admin:
      backend: postgres-operations-redash
      name: admin
      options:
        db_name: redash
        default_ttl: {{ SIX_MONTHS }}
        max_ttl: {{ SIX_MONTHS }}
        creation_statements: >-
          {% raw %}CREATE USER "{{name}}" WITH PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'{% endraw %} IN ROLE "rds_superuser" INHERIT CREATEROLE CREATEDB;
          GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO {% raw %}"{{name}}"{% endraw %} WITH GRANT OPTION;
          GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO {% raw %}"{{name}}"{% endraw %} WITH GRANT OPTION;
        {% raw %}
        revocation_statements: >-
          GRANT "{{name}}" TO odldevops WITH ADMIN OPTION;
          REASSIGN OWNED BY "{{name}}" TO "rds_superuser";
          DROP OWNED BY "{{name}}";
          REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM "{{name}}";
          REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM "{{name}}";
          REVOKE USAGE ON SCHEMA public FROM "{{name}}";
          DROP USER "{{name}}";
        {% endraw %}
    postgresql_redash_app:
      backend: postgres-operations-redash
      name: redash
      options:
        db_name: redash
        default_ttl: {{ SIX_MONTHS }}
        max_ttl: {{ SIX_MONTHS }}
        creation_statements: >-
          {% raw %}CREATE USER "{{name}}" WITH PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'{% endraw %} IN ROLE "redash" INHERIT;
          GRANT {% raw %}"{{name}}"{% endraw %} TO odldevops WITH ADMIN OPTION;
          GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO {% raw %}"{{name}}"{% endraw %} WITH GRANT OPTION;
          GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO {% raw %}"{{name}}"{% endraw %} WITH GRANT OPTION;
          ALTER DEFAULT PRIVILEGES FOR USER {% raw %}"{{name}}"{% endraw %} IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO "redash" WITH GRANT OPTION;
          ALTER DEFAULT PRIVILEGES FOR USER {% raw %}"{{name}}"{% endraw %} IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO "redash" WITH GRANT OPTION;
        {% raw %}
        revocation_statements: >-
          GRANT "{{name}}" TO odldevops WITH ADMIN OPTION;
          REASSIGN OWNED BY "{{name}}" TO "redash";
          DROP OWNED BY "{{name}}";
          REVOKE "redash" FROM "{{name}}";
          REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM "{{name}}";
          REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM "{{name}}";
          REVOKE USAGE ON SCHEMA public FROM "{{name}}";
          DROP USER "{{name}}";
        {% endraw %}
    postgresql_redash_readonly:
      backend: postgres-operations-redash
      name: readonly
      options:
        db_name: redash
        default_ttl: {{ SIX_MONTHS }}
        max_ttl: {{ SIX_MONTHS }}
        creation_statements: >-
          {% raw %}CREATE USER "{{name}}" WITH PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'{% endraw %};
          GRANT {% raw %}"{{name}}"{% endraw %} TO odldevops WITH ADMIN OPTION;
          GRANT SELECT ON ALL TABLES IN SCHEMA public TO {% raw %}"{{name}}";{% endraw %}
          GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO {% raw %}"{{name}}";{% endraw %}
          ALTER DEFAULT PRIVILEGES FOR USER {% raw %}"{{name}}"{% endraw %} IN SCHEMA public GRANT SELECT ON TABLES TO "redash" WITH GRANT OPTION;
          ALTER DEFAULT PRIVILEGES FOR USER {% raw %}"{{name}}"{% endraw %} IN SCHEMA public GRANT SELECT ON SEQUENCES TO "redash" WITH GRANT OPTION;
        {% raw %}
        revocation_statements: >-
          GRANT "{{name}}" TO odldevops WITH ADMIN OPTION;
          REASSIGN OWNED BY "{{name}}" TO "redash";
          DROP OWNED BY "{{name}}";
          REVOKE "redash" FROM "{{name}}";
          REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM "{{name}}";
          REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM "{{name}}";
          REVOKE USAGE ON SCHEMA public FROM "{{name}}";
          DROP USER "{{name}}";
        {% endraw %}
