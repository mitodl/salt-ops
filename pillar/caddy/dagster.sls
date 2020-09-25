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
      - github.com/greenpau/caddy-auth-jwt
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
                  - path:
                      - /login*
                terminal: true
                handle:
                - handler: auth_portal
                  auth_url_path: /login
                  primary: true
                  backends:
                    - method: local
                      path: /var/lib/caddy/auth/users.json
                      realm: local
                  jwt:
                    token_name: access_token
                    token_issuer: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ ENVIRONMENT }}/caddy-jwt-issuer>data>value
                    token_secret: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ ENVIRONMENT }}/caddy-jwt-secret>data>value
                  ui:
                    allow_role_selection: false
                    auto_redirect_url: ''
                    logo_description: Dagster
                    logo_url: https://dagster.io/images/logo.png
                    private_links:
                      - title: Dagster
                        link: /
              - match:
                  - host: {{ server_domain_names|tojson }}
                handle:
                  - handler: authentication
                    providers:
                      jwt:
                        primary: true
                        auth_url_path: /login
                        trusted_tokens:
                          - token_name: access_token
                            token_issuer: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ ENVIRONMENT }}/caddy-jwt-issuer>data>value
                            token_secret: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ ENVIRONMENT }}/caddy-jwt-secret>data>value
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
