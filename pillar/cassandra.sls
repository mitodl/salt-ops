{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set lan_nodes = [] %}
{% for host, addr in salt.saltutil.runner(
    'mine.get',
    tgt='G@roles:cassandra and G@environment:{}'.format(ENVIRONMENT),
    fun='grains.item',
    tgt_type='compound').items() %}
{% do lan_nodes.append('{0}'.format(addr['ec2:local_ipv4'])) %}
{% endfor %}
{% set listen_address = salt.grains.get('ec2:local_ipv4') %}

cassandra:
  configuration:
    cluster_name: {{ grains.get('environment', 'dev') }}
    commitlog_directory: /var/lib/cassandra/commitlog
    commitlog_sync: periodic
    commitlog_sync_period_in_ms: 10000
    data_file_directories:
      - /var/lib/cassandra/data/
    endpoint_snitch: GossipingPropertyFileSnitch
    listen_address: {{ listen_address }}
    partitioner: org.apache.cassandra.dht.Murmur3Partitioner
    rpc_address: {{ listen_address }}
    saved_caches_directory: /var/lib/cassandra/saved_caches
    seed_provider:
      - class_name: org.apache.cassandra.locator.SimpleSeedProvider
        parameters:
          - seeds: {{ lan_nodes|join(',')|tojson }}
    # authenticator: PasswordAuthenticator

python_dependencies:
  python_libs:
    - pycassa
    - cassandra-driver
    - testinfra
