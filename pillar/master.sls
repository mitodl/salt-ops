salt_master:
  git_remotes:
    - https://github.com/mitodl/master-formula
  lookup:
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
    ext_pillar:
      name: ext_pillar
      params:
        reclass:
          inventory_base_uri: /etc/reclass
  minion_configs:
    extra_settings:
      nested: False
      id: secretary
  aws:
    providers:
      - name: mitx
        id: use-instance-role-credentials
        key: use-instance-role-credentials
        keyname: salt-master-prod
        private_key_path: /etc/salt/keys/aws
      - name: mitx-stage
        id: use-instance-role-credentials
        key: use-instance-role-credentials
        keyname: salt-master-stage
        private_key_path: /etc/salt/keys/aws
        region: us-west-2
