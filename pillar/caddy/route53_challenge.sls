caddy:
  config:
    apps:
      tls:
        automation:
          policies:
            - issuer:
                module: acme
                challenges:
                  dns:
                    provider:
                      name: route53
                      max_retries: 10
