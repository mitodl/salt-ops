mine_functions:
  network.ip_addrs: [eth0]
  network.get_hostname: []
  grains.item:
    - external_ip
    - ec2:local_ipv4
