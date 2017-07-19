#!jinja|yaml

{% set mongodb_admin_username = 'admin' %}
{% set MONGO_ADMIN_USER = 'admin' %}
{% set mongodb_admin_password = salt.random.get_str(20) %}

mine_functions:
  network.ip_addrs: [eth0]
  network.get_hostname: []

mongodb:
  overrides:
    install_pkgrepo: False
    pkgs:
      - mongodb
    service_name: mongodb
  admin_username: {{ mongodb_admin_username }}
  admin_password: {{ mongodb_admin_password }}
