# Add MySQL settings to client config in order to allow for adding datadog user
# to database for using MySQL integration

{% set mysql_settings = salt.pillar.get('mysql:credentials') %}
minion_mysql_connection_settings:
  file.managed:
    - name: /etc/salt/minion.d/mysql_settings.conf
    - contents: |
        {{ mysql_settings | yaml(False) | indent(8) }}
    - watch_in:
        - service: salt_minion_running
    - makedirs: True
{% endfor %}
