salt_master:
  libgit:
    release: '0.27.3'
    hash: 50a57bd91f57aa310fb7d5e2a340b3779dc17e67b4e7e66111feac5c2432f1a5
  overrides:
    pkgs:
      - build-essential
      - curl
      - emacs
      - git
      - libffi-dev
      - libssh2-1-dev
      - libssl-dev
      - mosh
      - python-dev
      - python-pip
      - reclass
      - salt-api
      - salt-cloud
      - salt-doc
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
      emailAddress: mitx-devops@mit.edu
      bits: 4096
      CN: salt.odl.mit.edu
      ST: MA
      L: Boston
      O: MIT
      OU: Office of Digital Learning
  aws:
    providers:
      - name: mitx
        id: use-instance-role-credentials
        key: use-instance-role-credentials
        keyname: salt-master-prod
        private_key_path: /etc/salt/keys/aws/salt-master-prod.pem
        extra_params:
          script_args: -U -F -A salt.private.odl.mit.edu
          sync_after_install: all
          delete_ssh_keys: True
