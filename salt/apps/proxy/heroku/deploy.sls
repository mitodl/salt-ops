{% set app_name = salt.pillar.get('heroku:app_name') %}

configure_salt_proxy:
  salt_proxy.configure_proxy:
    - proxyname: {{ app_name }}
    - start: True

set_proxy_grain_role:
  module.run:
    - name: grains.set
    - key: roles
    - value:
        - proxy
