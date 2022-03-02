{% set env_settings = salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml", dest=None)|load_yaml %}
{% set SIX_MONTHS = '4368h' %}

vault:
  roles:

    {# Production and QA environments are handled separately with the
       conditionals below because of different Vault plugins being used for
       different mount points, due to the mount points having been created
       at different times. Vault used to have separate backend types for MySQL,
       Postgres, etc., and then they created a general purpose database backend
       type that has support for the different engines. #}

    {% for env in ['mitx-qa', 'mitx-production'] %}
    {% for app in ['mitxcas'] %}
    postgresql_{{ env }}_{{ app }}_admin:
      backend: postgres-{{ env }}-{{ app }}
      name: admin
      options:
        db_name: {{ app }}
        default_ttl: {{ SIX_MONTHS }}
        max_ttl: {{ SIX_MONTHS }}
        creation_statements: >-
          {% raw %}CREATE USER "{{name}}" WITH PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'{% endraw %} IN ROLE "rds_superuser" INHERIT CREATEROLE CREATEDB;
          GRANT "{{app}}" TO {% raw %}"{{name}}"{% endraw %} WITH ADMIN OPTION;
          GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO {% raw %}"{{name}}"{% endraw %} WITH GRANT OPTION;
          GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO {% raw %}"{{name}}"{% endraw %} WITH GRANT OPTION;
        {% raw %}
        revocation_statements: >-
          GRANT "{{name}}" TO odldevops WITH ADMIN OPTION;
          REASSIGN OWNED BY "{{name}}" TO {% endraw %}"{{ app }}"{% raw %};
          DROP OWNED BY "{{name}}";
          REVOKE {% endraw %}"{{ app }}"{% raw %} FROM "{{name}}";
          REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM "{{name}}";
          REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM "{{name}}";
          REVOKE USAGE ON SCHEMA public FROM "{{name}}";
          DROP USER "{{name}}";
        {% endraw %}
    postgresql_{{ env }}_{{ app }}:
      backend: postgres-{{ env }}-{{ app }}
      name: {{ app }}
      options:
        db_name: {{ app }}
        default_ttl: {{ SIX_MONTHS }}
        max_ttl: {{ SIX_MONTHS }}
        creation_statements: >-
          {% raw %}CREATE USER "{{name}}" WITH PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'{% endraw %} IN ROLE "{{ app }}" INHERIT;
          GRANT {% raw %}"{{name}}"{% endraw %} TO odldevops WITH ADMIN OPTION;
          GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO {% raw %}"{{name}}"{% endraw %} WITH GRANT OPTION;
          GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO {% raw %}"{{name}}"{% endraw %} WITH GRANT OPTION;
          ALTER DEFAULT PRIVILEGES FOR USER {% raw %}"{{name}}"{% endraw %} IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO "{{ app }}" WITH GRANT OPTION;
          ALTER DEFAULT PRIVILEGES FOR USER {% raw %}"{{name}}"{% endraw %} IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO "{{ app }}" WITH GRANT OPTION;
        {% raw %}
        revocation_statements: >-
          GRANT "{{name}}" TO odldevops WITH ADMIN OPTION;
          REASSIGN OWNED BY "{{name}}" TO {% endraw %}"{{ app }}"{% raw %};
          DROP OWNED BY "{{name}}";
          REVOKE {% endraw %}"{{ app }}"{% raw %} FROM "{{name}}";
          REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM "{{name}}";
          REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM "{{name}}";
          REVOKE USAGE ON SCHEMA public FROM "{{name}}";
          DROP USER "{{name}}";
        {% endraw %}
    postgresql_{{ env }}_{{ app }}_readonly:
      backend: postgres-{{ env }}-{{ app }}
      name: readonly
      options:
        db_name: {{ app }}
        default_ttl: {{ SIX_MONTHS }}
        max_ttl: {{ SIX_MONTHS }}
        creation_statements: >-
          {% raw %}CREATE USER "{{name}}" WITH PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'{% endraw %};
          GRANT {% raw %}"{{name}}"{% endraw %} TO odldevops;
          GRANT SELECT ON ALL TABLES IN SCHEMA public TO {% raw %}"{{name}}";{% endraw %}
          GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO {% raw %}"{{name}}";{% endraw %}
          ALTER DEFAULT PRIVILEGES FOR USER {% raw %}"{{name}}"{% endraw %} IN SCHEMA public GRANT SELECT ON TABLES TO "{{ app }}" WITH GRANT OPTION;
          ALTER DEFAULT PRIVILEGES FOR USER {% raw %}"{{name}}"{% endraw %} IN SCHEMA public GRANT SELECT ON SEQUENCES TO "{{ app }}" WITH GRANT OPTION;
        {% raw %}
        revocation_statements: >-
          GRANT "{{name}}" TO odldevops WITH ADMIN OPTION;
          REASSIGN OWNED BY "{{name}}" TO {% endraw %}"{{ app }}"{% raw %};
          DROP OWNED BY "{{name}}";
          REVOKE {% endraw %}"{{ app }}"{% raw %} FROM "{{name}}";
          REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM "{{name}}";
          REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM "{{name}}";
          REVOKE USAGE ON SCHEMA public FROM "{{name}}";
          DROP USER "{{name}}";
        {% endraw %}
    {% endfor %}{# end of app loop #}
    {% endfor %}{# environment loop #}
