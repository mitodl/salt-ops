{% set mysql_creds = salt.vault.read('mysql-{env}/creds/datadog'.format(env=salt.grains.get('environment')), ignore_invalid=True) %}

{% if mysql_creds %}
datadog:
  integrations:
    mysql:
      settings:
        instances:
          - server: mysql.service.consul
            user: {{ mysql_creds.data.username }}
            pass: {{ mysql_creds.data.password }}
            tags:
              - {{ salt.grains.get('environment') }}
{% endif %}
