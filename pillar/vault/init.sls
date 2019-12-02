vault:
  overrides:
    version: 1.2.3
    keybase_users:
      - renaissancedev
      - shaidar
      - markbreedlove
    secret_shares: 3
    secret_threshold: 2
    config:
      backend:
        consul:
          address: 127.0.0.1:8500
          path: vault
      listener:
        tcp:
          address: 0.0.0.0:8200
          tls_cert_file: /etc/salt/ssl/certs/vault.odl.mit.edu.crt
          tls_key_file: /etc/salt/ssl/certs/vault.odl.mit.edu.key
      log_level: WARN
      log_format: json
      telemetry:
        dogstatsd_addr: 127.0.0.1:8125
  ssl:
    cert_params:
      CN: vault.odl.mit.edu
      emailAddress: mitx-devops@mit.edu
      bits: 4096
      ST: MA
      L: Cambridge
      O: Massachussetts Institute of Technology
      OU: Office of Digital Learning

vault.verify: False
