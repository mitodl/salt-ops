salt_master:
  lookup:
    pkgs:
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
    pip_deps:
      - pygit2
      - apache-libcloud
      - PyOpenssl
    api_users:
      - name: admin
        password: |
          -----BEGIN PGP MESSAGE-----
          Version: GnuPG v2

          hQIMA6eRLifFOVfTAQ/+M88z6MJwQSicPkqhS3Yn+NcJyIA79kW+ZhGxLE2uJqcz
          8WU/GFGAplZGLm6wOInbM7raUs0CC+fudqunUxo8Dk51BjIMddR7L2iVEQ1HMiG4
          XDprnOQuzu0lRzfEGanEvHLYc7eJASYil1iA4M69bPSbmMOS5vWVG8Xul64T8wXl
          tsameqOhCVLSWq1ltZzRVfYep+xDSu1l+haeAzSrX2gbVaEsVy7tQ2vM/sjF4YQU
          TFXPxPuKhOpxUmtD3ZDQnGVpDO3INA9WlvOJ2lIjBpwYaVHwloiwPrAnPM+H25XG
          HXnbeYabovw0JxyH+sJiZnSA9/ITWRMc9/kv0F/Vn+KVTylu8v85+6T+ujoMoGe8
          yDoqNARtHlF/ygA5G5AJM5wvvfEK6LL/EH79pNcUcRlYo0OWve7/reEdUPeEeqT8
          /3U5DKnmJybyyQSC7wq62jXLS7sIW6W1nDaNQtRAgvQsNqI1nV0q/42lB1LSn13g
          hxxVZ9rcKDgag5vreazR7S96rTIC64dAFx/Q+kGJe33iMAeGSVZg8dqQGo4kxtYd
          cUcAP1SsdF4CvRT3PWdTMOLfwXwSR/rSxBzhLI9SrW+ws44tuT3zC/HxHX5ArXdH
          dhyFQFPUNLsxDyvhtBZD6GRf0P3dqScLfRUzWOayr21nApLcBhA52aYaqdILPbTS
          XgFsQCDMwaXoKcCI7KYz+kXwX6ZUM9yFUSdSIBGhcx7ql/4QzbBg+YPe17+pGLl2
          YlDjvdlYyb/Qda2ZbaNtGoPR8iMKgD8YE8ySRH8AdtHdik0KydXrf/rpUGYbQGI=
          =ZGbB
          -----END PGP MESSAGE-----
        permissions:
          - '*'
          - '@runner'
          - '@wheel'
          - '@jobs'
  ssl:
    cert_path: /etc/salt/ssl/certs/salt.mitx.mit.com.crt
    key_path: /etc/salt/ssl/certs/salt.mitx.mit.com.key
    cert_params:
      emailAddress: mitx-devops@mit.edu
      bits: 4096
      CN: salt.mitx.mit.edu
      ST: MA
      L: Boston
      O: MIT
      OU: Office of Digital Learning
  extra_configs:
    extfs:
      fileserver_backends:
        - git
        - roots
      gitfs_provider: pygit2
      git_remotes:
        - https://github.com/mitodl/salt-ops
        - https://github.com/mitodl/master-formula
    ext_pillar:
      name: ext_pillar
      params:
        git:
          - git@github.mit.edu:mitx-devops/salt-pillar:
              - privkey: /etc/salt/keys/ssh/github_mit
              - pubkey: /etc/salt/keys/ssh/github_mit.pub
        reclass:
          inventory_base_uri: /etc/reclass
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
        private_key_path: /etc/salt/keys/aws
        sync_after_install: all
