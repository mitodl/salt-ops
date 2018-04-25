#!jinja|yaml|gpg

{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set BUSINESS_UNIT = salt.grains.get('business_unit', 'residential') %}

rabbitmq:
  overrides:
    version: '3.6.15-1'
  configuration:
    rabbit:
      cluster_partition_handling: '@autoheal'
      auth_backends:
        - '@rabbit_auth_backend_internal'
    autocluster:
      version: '0.10.0'
      backend: '@consul'
      consul_host: localhost
      consul_port: 8500
      consul_svc: rabbitmq-cluster
      cluster_name: {{ ENVIRONMENT }}
  env:
    RABBITMQ_USE_LONGNAMES: 'true'
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
