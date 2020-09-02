{% set app_name = 'dagster' %}
{% set env_settings = salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml", dest=None)|load_yaml %}
{% set ENVIRONMENT = salt.grains.get('environment', 'data-qa') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set server_domain_names = env_data.purposes[app_name].domains %}

caddy:
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
