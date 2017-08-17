#!jinja|yaml

{% set mongodb_admin_username = 'admin' %}
{% set mongodb_admin_password = 'changeme' %}

mine_functions:
  network.ip_addrs: [eth0]
  network.get_hostname: []

mongodb:
  admin_username: {{ mongodb_admin_username }}
  admin_password: {{ mongodb_admin_password }}
  users:
    - {{ mongodb_admin_username }}
