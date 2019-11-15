{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set SIX_MONTHS = '4368h' %}

vault:
  roles:
    {% for env in ['mitx-qa', 'mitx-production', 'mitxpro-qa', 'mitxpro-production'] %}
    # This will need to be removed once we start using the database backend
    {% if env in ['mitx-qa', 'mitx-production'] %}
    admin-mysql-{{ env }}:
      backend: mysql-{{ env }}
      name: admin
      options:
        sql: {% raw %}"CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';
        GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, REFERENCES, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, EVENT, TRIGGER ON `%`.* TO '{{name}}' WITH GRANT OPTION;"{% endraw %}
        revocation_sql: {% raw %}"DROP USER '{{name}}';"{% endraw %}
    readonly-mysql-{{ env }}:
      backend: mysql-{{ env }}
      name: readonly
      options:
        sql: {% raw %}"CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT, SHOW VIEW ON `%`.* TO '{{name}}'@'%';"{% endraw %}
        revocation_sql: {% raw %}"DROP USER '{{name}}';"{% endraw %}
    datadog-mysql-{{ env }}:
      backend: mysql-{{ env }}
      name: datadog
      options:
        sql: >-
          {% raw -%}
          CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';
          GRANT REPLICATION CLIENT ON *.* TO '{{name}}'@'%';
          GRANT PROCESS ON *.* TO '{{name}}'@'%';
          GRANT SELECT ON `performance_schema`.* TO '{{name}}'@'%';
          {%- endraw %}
        revocation_sql: {% raw %}"DROP USER '{{name}}';"{% endraw %}
    {% else %}
    admin-mysql-{{ env }}:
      backend: mysql-{{ env }}
      name: admin
      options:
        db_name: {{ env|replace('-', '') }}
        creation_statements: {% raw %}"CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';
        GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, REFERENCES, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, EVENT, TRIGGER ON `%`.* TO '{{name}}' WITH GRANT OPTION;"{% endraw %}
        revocation_statements: {% raw %}"DROP USER '{{name}}';"{% endraw %}
    readonly-mysql-{{ env }}:
      backend: mysql-{{ env }}
      name: readonly
      options:
        db_name: {{ env|replace('-', '') }}
        creation_statements: {% raw %}"CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT, SHOW VIEW ON `%`.* TO '{{name}}'@'%';"{% endraw %}
        revocation_statements: {% raw %}"DROP USER '{{name}}';"{% endraw %}
    datadog-mysql-{{ env }}:
      backend: mysql-{{ env }}
      name: datadog
      options:
        db_name: {{ env|replace('-', '') }}
        creation_statements: >-
          {% raw -%}
          CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';
          GRANT REPLICATION CLIENT ON *.* TO '{{name}}'@'%';
          GRANT PROCESS ON *.* TO '{{name}}'@'%';
          GRANT SELECT ON `performance_schema`.* TO '{{name}}'@'%';
          {%- endraw %}
        revocation_statements: {% raw %}"DROP USER '{{name}}';"{% endraw %}
    {% endif %}
    datadog-rabbitmq-{{ env }}:
      backend: rabbitmq-{{ env }}
      name: datadog
      options:
        tags: monitoring
    admin-rabbitmq-{{ env }}:
      backend: rabbitmq-{{ env }}
      name: admin
      options:
        tags: administrator
    datadog-mongodb-{{ env }}:
      backend: mongodb-{{ env }}
      name: datadog
      options:
        db_name: mongodb
        creation_statements: {{ '{"roles": [{"role": "read"}, {"db": "admin", "role": "clusterMonitor"}, {"db": "local", "role": "read"}], "db": "admin"}'|yaml_dquote }}
    admin-mongodb-{{ env }}:
      backend: mongodb-{{ env }}
      name: admin
      options:
        db_name: mongodb
        creation_statements: {{ '{"roles": [{"role": "superuser"}, {"role": "root"}], "db": "admin"}'|yaml_dquote }}
    {% set env_data = env_settings['environments'][env] %}
    {% set bucket_prefix = env_data.secret_backends.aws.bucket_prefix %}
    {% for purpose in env_data.purposes %}
    {% set purpose_suffix = purpose|replace('-', '_') %}
    {% for role in env_data.secret_backends.mysql.role_prefixes %}
    {% set db_name = role|replace('-', '_') ~ '_' ~ purpose_suffix %}
    # This will need to be removed once we start using the database backend
    {% if env in ['mitx-qa', 'mitx-production'] %}
    {{ role }}-mysql-{{ env }}-{{ purpose }}:
      backend: mysql-{{ env }}
      name: {{ role }}-{{ purpose }}
      options:
        sql: "CREATE USER {% raw %}'{{name}}'@'%'{% endraw %} IDENTIFIED BY {% raw %}'{{password}}'{% endraw %};GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, INDEX, DROP, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES ON {{ db_name }}.* TO {% raw %}'{{name}}'{% endraw %}@'%';"
        revocation_sql: {% raw %}"DROP USER '{{name}}';"{% endraw %}
    {% else %}
    {{ role }}-mysql-{{ env }}-{{ purpose }}:
      backend: mysql-{{ env }}
      name: {{ role }}-{{ purpose }}
      options:
        db_name: {{ env|replace('-', '') }}
        creation_statements: "CREATE USER {% raw %}'{{name}}'@'%'{% endraw %} IDENTIFIED BY {% raw %}'{{password}}'{% endraw %};GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, INDEX, DROP, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES ON {{ db_name }}.* TO {% raw %}'{{name}}'{% endraw %}@'%';"
        revocation_statements: {% raw %}"DROP USER '{{name}}';"{% endraw %}
    {% endif %}
    {% endfor %}{# role loop for mysql #}
    {% for role in env_data.secret_backends.rabbitmq.role_prefixes %}
    {{ role }}-rabbitmq-{{ env }}-{{ purpose }}:
      backend: rabbitmq-{{ env }}
      name: {{ role }}-{{ purpose }}
      options:
        vhosts: '{"/{{ role }}_{{ purpose_suffix }}": {"write": ".*", "read": ".*", "configure": ".*"}}'
    {% endfor %}{# role loop for RabbitMQ #}
    {% for role in env_data.secret_backends.mongodb.role_prefixes %}
    {% set role_json = '{"roles": [{"role": "readWrite"}], "db": "' ~ role ~ '_' ~ purpose_suffix ~ '"}' %}
    {{ role }}-mongodb-{{ purpose }}-{{ env }}:
      backend: mongodb-{{ env }}
      name: {{ role }}-{{ purpose }}
      formatted_option: db
      options:
        db_name: mongodb
        creation_statements: {{ role_json|yaml_dquote }}
    {% endfor %}{# role loop for MongoDB #}
    {% load_json as bucket_policy %}
    {
        "Statement": [
            {
                "Resource": [
                {% for use in env_data.secret_backends.aws.bucket_uses %}
                    "arn:aws:s3:::{{ bucket_prefix }}-{{ use }}-{{ purpose }}-{{ env }}",
                    "arn:aws:s3:::{{ bucket_prefix }}-{{ use }}-{{ purpose }}-{{ env }}/*"{% if not loop.last %},{% endif %}
                {% endfor %}
                ],
                "Action": [
                    "s3:*Object*",
                    "s3:ListAllMyBuckets",
                    "s3:ListBucket"
                ],
                "Effect": "Allow"
            }
        ],
        "Version": "2012-10-17"
    }
    {% endload %}
    read_and_write_iam_bucket_access_for_mitx_{{ purpose }}_in_{{ env }}:
      backend: aws-mitx
      name: {{ bucket_prefix }}-s3-{{ purpose }}-{{ env }}
      options:
        policy: '{{ bucket_policy|tojson }}'
    {% endfor %}{# purpose loop #}
    {% if not 'xpro' in env %}
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
    {% endif %}
    {% endfor %}{# environment loop #}
