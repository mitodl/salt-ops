fluentd:
  configs:
    - name: match_all_tls
      settings:
      - directive: match
          directive_arg: '**'
          attrs:
            - '@type': forward
            - transport: tls
            - tls_client_cert_path: '/etc/fluent/fluentd.crt'
            - tls_client_private_key_path: '/etc/fluent/fluentd.key'
            - tls_ca_cert_path: '/etc/fluent/ca.crt'
            - tls_allow_self_signed_cert: true
            - tls_verify_hostname: false
            - self_hostname: {{ salt.grains.get('ipv4')[0] }}
            - nested_directives:
                - directive: server
                  attrs:
                    - host: operations-fluentd.query.consul
                    - port: 5001
