#!jinja|yaml|gpg

{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set BUSINESS_UNIT = salt.grains.get('business_unit', 'residential') %}

rabbitmq:
  overrides:
    version: '3.7.4-1'
    erlang_version: '1:20.1'
  configuration:
    cluster_partition_handling: autoheal
    cluster_partition_handling.pause_if_all_down.recover: autoheal
    cluster_formation.peer_discovery_backend: rabbit_peer_discovery_consul
    cluster_formation.consul.host: localhost
    cluster_formation.consul.port: 8500
    cluster_formation.consul.scheme: http
    cluster_formation.consul.use_longname: 'true'
    cluster_formation.consul.svc: rabbitmq-{{ ENVIRONMENT }}
    auth_backends.1: rabbit_auth_backend_internal
  users:
    - name: guest
      state: absent
    - name: admin
      state: present
      settings:
        tags:
          - administrator
        password: {{ salt.vault.read('secret-{BUSINESS_UNIT}/{ENVIRONMENT}/rabbitmq-admin-password'.format(
                     BUSINESS_UNIT=BUSINESS_UNIT, ENVIRONMENT=ENVIRONMENT)).data.value }}
  erlang_cookie: {{ salt.vault.read(
      'secret-{BUSINESS_UNIT}/{ENVIRONMENT}/erlang_cookie'.format(
          BUSINESS_UNIT=BUSINESS_UNIT, ENVIRONMENT=ENVIRONMENT)).data.value }}
