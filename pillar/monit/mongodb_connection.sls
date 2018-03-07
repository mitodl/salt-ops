#!jinja|yaml

{% set env = salt.grains.get('environment', 'mitx-qa') %}
{% set purpose = salt.grains.get('purpose', 'current-residential-live') %}
{% set mongodb_host = 'mongodb-master.service.consul' %}
{% set mongodb_port = 27017 %}
{% set mongodb_contentstore_creds = salt.vault.read('mongodb-{env}/creds/contentstore-{purpose}'.format(env=env, purpose=purpose)) %}

monit_app:
  notification: 'slack'
  modules:
    mysql_connection:
      host:
        custom:
          name: {{ mongodb_host }}
        with:
          address: {{ mongodb_host }}
        if:
          failed: port {{ mongodb_port }} protocol mongodb username "{{ mongodb_contentstore_creds.data.username }}" password "{{ mongodb_contentstore_creds.data.password }}"
          action: exec "/bin/sh -c /usr/local/bin/slack.sh"
