{% set app_name = 'dagster' %}
{% set env_settings = salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml", dest=None)|load_yaml %}
{% set ENVIRONMENT = salt.grains.get('environment', 'data-qa') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set business_unit = env_data.business_unit %}
{% set server_domain_names = env_data.purposes[app_name].domains %}

caddy:
  auth:
    local_users:
      - username: tmacey
        password_hash: __vault__::secret-operations/global/caddy-auth-users/tmacey>data>password_hash
        email: __vault__::secret-operations/global/caddy-auth-users/tmacey>data>email
        roles:
          - superadmin
      - username: shaidar
        password_hash: __vault__::secret-operations/global/caddy-auth-users/shaidar>data>password_hash
        email: __vault__::secret-operations/global/caddy-auth-users/shaidar>data>email
        roles:
          - superadmin
      - username: pdpinch
        password_hash: __vault__::secret-operations/global/caddy-auth-users/pdpinch>data>password_hash
        email: __vault__::secret-operations/global/caddy-auth-users/pdpinch>data>email
        roles:
          - superadmin
      # - username: mbreedlove
      #   password_hash: __vault__::secret-operations/global/caddy-auth-users/mbreedlove>data>password_hash
      #   email: __vault__::secret-operations/global/caddy-auth-users/mbreedlove>data>email
      #   roles:
      #     - superadmin
      # - username: aroy
      #   password_hash: __vault__::secret-operations/global/caddy-auth-users/aroy>data>password_hash
      #   email: __vault__::secret-operations/global/caddy-auth-users/aroy>data>email
      #   roles:
      #     - superadmin
  install_from_repo: False
  custom_build:
    os: linux
    arch: amd64
    plugins:
      - github.com/greenpau/caddy-authorize
      - github.com/greenpau/caddy-auth-portal
  config:
    apps:
      http:
        servers:
          salt_api:
            listen:
              - ':443'
            routes:
              - match:
                  - host: {{ server_domain_names|tojson }}
                handle:
                handle:
                  - handler: subroute
                    routes:
                      - handle:
                          - handler: authentication
                            providers:
                              http_basic:
                                accounts:
                                  - username: pulumi
                                    # Password should be bcrypted and base64 encoded
                                    password: __vault__::secret-data/dagster-http-auth-password>data>value
                      - handler: headers
                        response:
                          add:
                            Connection:
                              - upgrade
                      - handler: reverse_proxy
                        transport:
                          protocol: http
                        upstreams:
                          - dial: 127.0.0.1:3000
