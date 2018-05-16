#!jinja|yaml

{% set rabbitmq_admin_password = 'changeme' %}

rabbitmq:
  overrides:
    version: '3.7.4-1'
    erlang_version: '1:20.1'
  configuration:
    disk_free_limit.relative: 0.2
    auth_backends.1: rabbit_auth_backend_internal
  users:
    - name: guest
      state: absent
    - name: admin
      state: present
      settings:
        tags:
          - administrator
        perms:
          - '/xqueue':
              - '.*'
              - '.*'
              - '.*'
          - '/celery':
              - '.*'
              - '.*'
              - '.*'
        password: {{ rabbitmq_admin_password }}
  vhosts:
    - name: '/xqueue'
      state: present
    - name: '/celery'
      state: present
