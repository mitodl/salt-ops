salt_master:
  lookup:
    pkgs:
      - curl
      - libssl-dev
      - build-essential
      - salt-doc
      - salt-api
      - salt-cloud
      - reclass
      - git
      - python-dev
      - libgit2-dev
      - python-pip
      - libffi-dev
      - libssh2-1-dev
    pip_deps:
      - boto>=2.35.0
      - apache-libcloud
      - PyOpenssl
      - pyyaml
      - requests
      - pygit2<0.24
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
  extra_configs:
    extfs:
      fileserver_backend:
        - git
        - roots
      gitfs_provider: pygit2
      gitfs_remotes:
        - https://github.com/mitodl/salt-ops:
            - root: salt
        - https://github.com/mitodl/master-formula
        - https://github.com/mitodl/elasticsearch-formula
        - https://github.com/mitodl/fluentd-formula
        - https://github.com/blarghmatey/aws-formula
    ext_pillar:
      git_pillar_provider: pygit2
      ext_pillar:
        - git:
            - master git@github.mit.edu:mitx-devops/salt-pillar:
                - privkey: /etc/salt/keys/ssh/github_mit
                - pubkey: /etc/salt/keys/ssh/github_mit.pub
  minion_configs:
    extra_settings:
      grains:
        roles:
          - master
  aws:
    providers:
      - name: mitx
        id: use-instance-role-credentials
        key: use-instance-role-credentials
        keyname: salt-master-prod
        private_key_path: /etc/salt/keys/aws/salt-master-prod.pem
        sync_after_install: all
