{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set lan_nodes = [] %}
{% for host, addr in salt.saltutil.runner(
    'mine.get',
    tgt='G@roles:scylladb and G@environment:{}'.format(ENVIRONMENT),
    fun='grains.item',
    tgt_type='compound').items() %}
{% do lan_nodes.append('{0}'.format(addr['ec2:local_ipv4'])) %}
{% endfor %}
{% set listen_address = salt.grains.get('ec2:local_ipv4') %}

scylladb:
  configuration:
    commitlog_directory: /var/lib/scylla/commitlog
    data_file_directories:
      - /var/lib/scylla/data/
    cluster_name: {{ grains.get('environment', 'dev') }}
    listen_address: {{ listen_address }}
    rpc_address: {{ listen_address }}
    seed_provider:
      - class_name: org.apache.cassandra.locator.SimpleSeedProvider
        parameters:
          - seeds: {{ lan_nodes|join(',') }}
    endpoint_snitch: GossipingPropertyFileSnitch
    # authenticator: PasswordAuthenticator

python_dependencies:
  python_libs:
    - pycassa
    - cassandra-driver
    - testinfra
