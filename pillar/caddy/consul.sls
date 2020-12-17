{% set app_name = 'consul' %}
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
      - github.com/caddy-dns/route53
  config:
    apps:
      http:
        servers:
          consul:
            listen:
              - ':443'
            routes:
              - match:
                  - host:
                      - consul-{{ ENVIRONMENT }}.odl.mit.edu
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
                                    password: __vault__::secret-operations/global/consul-caddy-http-auth-password>data>value
                          - handler: reverse_proxy
                            transport:
                              protocol: http
                            upstreams:
                              - dial: 127.0.0.1:8500
