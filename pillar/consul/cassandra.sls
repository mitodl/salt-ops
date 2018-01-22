consul:
  extra_configs:
    cassandra_service:
      service:
        name: cassandra
        port: 9160
        check:
          tcp: {{ salt.grains.get('ec2:local_ipv4') }}:9160
          interval: 10s
