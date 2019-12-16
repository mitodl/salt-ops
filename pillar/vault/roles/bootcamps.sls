vault:
  roles:
    bootcamps-app:
      backend: postgresql-bootcamps
      name: app
      options:
        {% raw %}
        sql: >-
          CREATE USER "{{name}}" WITH PASSWORD '{{password}}' VALID UNTIL '{{expiration}}' IN ROLE "bootcamp-ecommerce" INHERIT;
          GRANT "{{name}}" TO odldevops;
          GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "{{name}}" WITH GRANT OPTION;
          GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO "{{name}}" WITH GRANT OPTION;
          ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO "{{name}}" WITH GRANT OPTION;
          ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO "{{name}}" WITH GRANT OPTION;
        {% endraw %}
    bootcamps-readonly:
      backend: postgresql-bootcamps
      name: readonly
      options:
        {% raw %}
        sql: >-
          CREATE USER "{{name}}" WITH PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
          GRANT SELECT ON ALL TABLES IN SCHEMA public TO "{{name}}";
          GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO "{{name}}";
          ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO "{{name}}";
          ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO "{{name}}";
        {% endraw %}
