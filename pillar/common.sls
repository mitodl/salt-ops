{% set environment = salt.grains.get('environment') %}

mine_functions:
  network.ip_addrs: [eth0]
  network.get_hostname: []
  grains.item:
    - id
    - instance-id
    - external_ip
    - ec2:local_ipv4
    - ec2:local_ipv6
    - ec2:public_ipv4
    - ec2:public_ipv6

salt_minion:
  extra_configs:
    logging:
      log_granular_levels:
        salt: warning
        salt.loader: warning
    saltenvs:
      {% if 'production' in environment %}
      saltenv: production
      lock_saltenv: True
      pillarenv: production
      {% else %}
      saltenv: base
      pillarenv_from_saltenv: True
      {% endif %}
      state_top_saltenv: base
