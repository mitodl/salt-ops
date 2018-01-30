{% import_yaml salt.cp.cache_file("salt://environment_settings.yml") as env_settings %}
vault:
  overrides:
    version: 0.9.1
    keybase_users:
      - renaissancedev
      - pdpinch
      - shaidar
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
