{% set purpose = salt.grains.get('purpose') %}

salt_master:
  dns: {{ purpose }}.odl.mit.edu
  libgit:
    release: '0.28.3'
    hash: ee5344730fe11ce7c86646e19c2d257757be293f5a567548d398fb3af8b8e53b
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
    cert_path: /etc/salt/ssl/certs/salt.odl.mit.com.crt
    key_path: /etc/salt/ssl/certs/salt.odl.mit.com.key
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
