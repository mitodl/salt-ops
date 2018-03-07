#!jinja|yaml

{% set env = salt.grains.get('environment', 'mitx-qa') %}
{% set purpose = salt.grains.get('purpose', 'current-residential-live') %}
{% set edxapp_mysql_host = 'mysql.service.consul' %}
{% set edxapp_mysql_port = 3306 %}
{% set edxapp_mysql_creds = salt.vault.read('mysql-{env}/creds/edxapp-{purpose}'.format(env=env, purpose=purpose)) %}

monit_app:
  notification: 'slack'
  modules:
    mysql_connection:
      host:
        custom:
          name: {{ edxapp_mysql_host }}
        with:
          address: {{ edxapp_mysql_host }}
        if:
          failed: port {{ edxapp_mysql_port }} protocol mysql username "{{ edxapp_mysql_creds.data.username }}" password "{{ edxapp_mysql_creds.data.password }}"
          action: exec "/bin/sh -c /usr/local/bin/slack.sh"
