restart_salt_master_service_low_memory:
  local.cmd.run:
    - tgt: {{ data['id'] }}
    - arg:
        - systemctl restart salt-master
