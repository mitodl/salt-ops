{% set env = salt.grains.get('environment', 'mitx-qa') %}
{% set purpose = salt.grains.get('purpose', 'current-residential-live') %}
{% set mongodb_host = 'mongodb-master.service.consul' %}
{% set mongodb_port = 27017 %}

monit_app:
  modules:
    mongodb_connection:
      host:
        custom:
          name: {{ mongodb_host }}
        with:
          address: {{ mongodb_host }}
        if:
          failed: port {{ mongodb_port }} protocol mongodb
          action: exec "/bin/sh -c /usr/local/bin/slack.sh"
