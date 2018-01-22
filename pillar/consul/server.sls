{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set wan_nodes = [] %}
{% for host, addr in salt.saltutil.runner(
    'mine.get',
    tgt='G@roles:consul_server and G@environment:operations',
    fun='grains.item',
    tgt_type='compound').items() %}
{% do wan_nodes.append('{0}'.format(addr['ec2:local_ipv4'])) %}
{% endfor %}

consul:
  extra_configs:
    defaults:
      enable_syslog: True
      server: True
      skip_leave_on_interrupt: True
      rejoin_after_leave: True
      leave_on_terminate: False
      dns_config:
        allow_stale: True
        node_ttl: 30s
        service_ttl:
          "*": 30s
      telemetry:
        dogstatsd_addr: 127.0.0.1:8125
      bootstrap_expect: 3
      client_addr: 0.0.0.0
      addresses:
        dns: 0.0.0.0
        http: 0.0.0.0
      retry_join_wan: {{ wan_nodes }}
      acl_datacenter: {{ ENVIRONMENT }}
      acl_master_token: {{ salt.vault.read('secret-operations/{}/consul-acl-master-token'.format(ENVIRONMENT)).data.value }}
