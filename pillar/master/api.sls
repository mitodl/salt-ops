{% set alcali_internal_ip = salt.saltutil.runner('mine.get',
                                                  tgt='alcali*',
                                                  fun='network.ip_addrs') %}
{% set environment = salt.grains.get('environment', 'operations-qa') %}

salt_master:
  api_users:
    - name: pulumi
      password: __vault__:gen_if_missing:secret-operations/{{ environment }}/salt-master/api-users/pulumi>data>value
      permissions:
        - '@wheel'
  extra_configs:
    api:
      rest_cherrypy:
        port: 8080
        address: 0.0.0.0
        debug: True
        disable_ssl: True
        websockets: True
      external_auth:
        pam:
          tmacey:
            - '.*'
            - '@runner'
            - '@wheel'
            - '@jobs'
          shaidar:
            - '.*'
            - '@runner'
            - '@wheel'
            - '@jobs'
          mbrdlove:
            - '.*'
            - '@runner'
            - '@wheel'
            - '@jobs'
          pulumi:
            - '@wheel'
        rest:
          ^url: https://{{ alcali_internal_ip }}:8000/api/token/verify/
          admin:
            - .*
            - '@runner'
            - '@wheel'
            - '@jobs'
