{% import_yaml salt.cp.cache_file("salt://environment_settings.yml") as env_settings %}
vault:
  roles:
    {% for env in ['mitx-qa', 'mitx-production'] %}
    admin-mysql-{{ env }}:
      backend: mysql-{{ env }}
      name: admin
      options:
        sql: {% raw %}"CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT ALL ON `%`.* TO '{{name}}'@'%';"{% endraw %}
        revocation_sql: {% raw %}"DROP USER '{{name}}';"{% endraw %}
    readonly-mysql-{{ env }}:
      backend: mysql-{{ env }}
      name: readonly
      options:
        sql: {% raw %}"CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT, SHOW VIEW ON `%`.* TO '{{()name}}'@'%';"{% endraw %}
        revocation_sql: {% raw %}"DROP USER '{{name}}';"{% endraw %}
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
        db: admin
        roles: '["read", {"role": "clusterMonitor", "db": "admin"}, {"role": "read", "db": "local"}]'
    admin-mongodb-{{ env }}:
      backend: mongodb-{{ env }}
      name: admin
      options:
        db: admin
        roles: '["superuser", "root"]'
    {% for purpose in env_settings['environments'][env].purposes %}
    {% set purpose_suffix = purpose|replace('-', '_') %}
    {% for role in env_settings.edxapp_secret_backends.mysql.role_prefixes %}
    {{ role }}-mysql-{{ env }}-{{ purpose }}:
      backend: mysql-{{ env }}
      name: {{ role }}-{{ purpose }}
      options:
        sql: "CREATE USER {% raw %}'{{name}}'@'%'{% endraw %} IDENTIFIED BY {% raw %}'{{password}}'{% endraw %};GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, INDEX, DROP, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES ON {{ role }}_{{ purpose_suffix }}.* TO {% raw %}'{{name}}'{% endraw %}@'%';"
        revocation_sql: {% raw %}"DROP USER '{{name}}';"{% endraw %}
    {% endfor %}{# role loop for mysql #}
    {% for role in env_settings.edxapp_secret_backends.rabbitmq.role_prefixes %}
    {{ role }}-rabbitmq-{{ env }}-{{ purpose }}:
      backend: rabbitmq-{{ env }}
      name: {{ role }}-{{ purpose }}
      options:
        vhosts: '{"/{{ role }}_{{ purpose_suffix }}": {"write": ".*", "read": ".*", "configure": ".*"}}'
    {% endfor %}{# role loop for RabbitMQ #}
    {% for role in env_settings.edxapp_secret_backends.mongodb.role_prefixes %}
    {{ role }}-mongodb-{{ purpose }}-{{ env }}:
      backend: mongodb-{{ env }}
      name: {{ role }}-{{ purpose }}
      formatted_option: db
      options:
        db: '{{ role }}_{{ purpose_suffix|trim }}'
        roles: '["readWrite"]'
    {% endfor %}{# role loop for MongoDB #}
    read_and_write_iam_bucket_access_for_mitx_{{ purpose }}_in_{{ env }}:
      backend: aws-mitx
      name: mitx-s3-{{ purpose }}-{{ env }}
      options:
        policy: "{\"Version\": \"2012-10-17\", \"Statement\": [{\"Effect\": \"Allow\", \"Action\": [\"s3:*Object*\", \"s3:ListAllMyBuckets\", \"s3:ListBucket\"], \"Resource\": [\"arn:aws:s3:::mitx-grades-{{ purpose }}-{{ env }}\", \"arn:aws:s3:::mitx-grades-{{ purpose }}-{{ env }}/*\", \"arn:aws:s3:::mitx-storage-{{ purpose }}-{{ env }}\", \"arn:aws:s3:::mitx-storage-{{ purpose }}-{{ env }}/*\", \"arn:aws:s3:::mitx-etl-{{ purpose }}-{{ env }}\", \"arn:aws:s3:::mitx-etl-{{ purpose }}-{{ env }}/*\"]}]}"
    {% endfor %}{# purpose loop #}
    {% endfor %}{# environment loop #}
