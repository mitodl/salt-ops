{% set app_name = 'ocw-build' %}
{% set env_settings = salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml", dest=None)|load_yaml %}
{% set ENVIRONMENT = salt.grains.get('environment', 'applications-qa') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set business_unit = env_data.purposes[app_name].business_unit %}
{% set server_domain_names = env_data.purposes[app_name].domains %}
{% set env_map = {
    'rc-apps': {
        'target_branch': 'release-candidate'
    },
    'production-apps': {
        'target_branch': 'release'
    }
} %}

caddy:
  install_from_repo: False
  custom_build:
    os: linux
    arch: amd64
    plugins:
      - github.com/abiosoft/caddy-exec
      - github.com/abiosoft/caddy-hmac
      - github.com/abiosoft/caddy-json-parse
      - github.com/greenpau/caddy-trace
  config:
    apps:
      http:
        servers:
          ocw_build:
            listen:
              - ':443'
            routes:
              - match:
                  - host: {{ server_domain_names|tojson }}
                handle:
                - handler: subroute
                  routes:
                  - match:
                      - header_regexp:
                          X-Hub-Signature:
                            pattern: '[a-z0-9]+\=([a-z0-9]+)'
                        path:
                          - /build-content-webhook
                    handle:
                      - handler: subroute
                        routes:
                          - handle:
                              - algorithm: sha1
                                handler: hmac
                                secret: __vault__:gen_if_missing:secret-operations/global/github-hmac-secret-string>data>value
                          - handle:
                              - handler: json_parse
                          - match:
                              - expression: "{hmac.signature} == {http.regexp.1}"
                              - expression: "{json.ref}.endsWith(\"{{ env_map[ENVIRONMENT]['target_branch'] }}\")"
                            handle:
                              - handler: exec
                                command: /opt/ocw/webhook-publish.sh
                                timeout: 2h
                - handler: file_server
                  root: /opt/ocw/hugo-course-publisher/dist/
                  index_names:
                    - index.html
                    - index.htm
                - handler: subroute
                  routes:
                    - match:
                        - path:
                            - /coursemedia
                      handle:
                        - handler: file_server
                          root: /opt/ocw/open-learning-course-data
                - handler: subroute
                  routes:
                    - match:
                        - path:
                            - /status
                      handle:
                        - handler: static_response
                          body: OK
