{% set purpose = salt.grains.get('purpose') %}

salt_master:
  dns: {{ purpose }}.odl.mit.edu
  private_dns: {{ purpose }}.private.odl.mit.edu
  libgit:
    release: '0.28.2'
    hash: 42b5f1e9b9159d66d86fff0394215c5733b6ef8f9b9d054cdd8c73ad47177fc3
  overrides:
    pkgs:
      - build-essential
      - curl
      - git
      - libffi-dev
      - libssh2-1-dev
      - libssl-dev
      - mosh
      - python3-dev
      - python3-pip
      - tmux
      - vim
      - mariadb-client
      - postgresl
    pip_deps:
      - PyOpenssl
      - apache-libcloud
      - boto3
      - boto>=2.35.0
      - croniter
      - elasticsearch
      - python-consul
      - python-dateutil
      - pyyaml
      - requests
  ssl:
    cert_path: /etc/salt/ssl/certs/salt.odl.mit.edu.crt
    key_path: /etc/salt/ssl/certs/salt.odl.mit.edu.key
    cert_params:
      emailAddress: odl-devops@mit.edu
      bits: 4096
      CN: {{ purpose }}.odl.mit.edu
      ST: MA
      L: Cambridge
      O: MIT
      OU: Open Learning
  aws:
    providers:
      - name: mitx
        id: use-instance-role-credentials
        key: use-instance-role-credentials
        keyname: {{ purpose }}
        private_key_path: /etc/salt/keys/aws/{{ purpose }}.pem
        extra_params:
          script_args: -U -F -x python3 -A {{ purpose }}.private.odl.mit.edu
          sync_after_install: all
          delete_ssh_keys: True
