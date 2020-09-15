{% set app_name = 'dagster' %}
{% set env_settings = salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml", dest=None)|load_yaml %}
{% set ENVIRONMENT = salt.grains.get('environment', 'data-qa') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set business_unit = env_data.business_unit %}
{% set server_domain_names = env_data.purposes[app_name].domains %}

caddy:
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
                  - host: {{ server_domain_names|tojson }}
                handle:
                  - handler: headers
                    response:
                      add:
                        Connection:
                          - upgrade
                        Upgrade:
                          - websocket
                  - handler: reverse_proxy
                    transport:
                      protocol: http
                    upstreams:
                      - dial: 127.0.0.1:3000
              - match:
                  - path:
                      - /login
                terminal: true
                handle:
                - handler: authentication
                  providers:
                    portal:
                      auth_url_path: /login
                      backends:
                      - method: local
                        path: /var/lib/caddy/auth/users.json
                        realm: local
                      jwt:
                        token_issuer: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ ENVIRONMENT }}/caddy-jwt-issuer>data>value
                        token_secret: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ ENVIRONMENT }}/caddy-jwt-secret>data>value
                      primary: true
                      ui:
                        allow_role_selection: false
                        auto_redirect_url: ''
                        logo_description: Dagster
                        logo_url: https://dagster.io/images/logo.png
                        templates:
                          portal: assets/ui/portal.template

