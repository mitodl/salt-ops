refresh_master_vault_token:
  vault.ec2_minion_authenticated:
    - role: salt-master
    - is_master: True

restart_salt_minion_process:
  cmd.run:
    - name: 'salt-call --local service.restart salt-minion'
    - bg: True
    - onchanges:
        - vault: refresh_master_vault_token

restart_salt_master_process:
  cmd.run:
    - name: 'salt-call --local service.restart salt-master'
    - bg: True
    - onchanges:
        - vault: refresh_master_vault_token
