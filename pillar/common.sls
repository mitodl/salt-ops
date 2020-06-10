mine_functions:
  network.ip_addrs: []
  network.get_hostname: []
  grains.item:
    - id
    - instance-id
    - external_ip
    - ec2:local_ipv4
    - ec2:local_ipv6
    - ec2:public_ipv4
    - ec2:public_ipv6
    - network:private_ipv4

salt_minion:
  extra_configs:
    logging:
      log_granular_levels:
        salt: warning
        salt.loader: warning
