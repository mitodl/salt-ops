{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set zk_release_id = salt.sdb.get('sdb://consul/zookeeper/' ~ ENVIRONMENT ~ '/release-id') %}
{% if not zk_release_id %}
{% set zk_release_id = 'v1' %}
{% endif %}

bookkeeper:
  config:
    extraServerComponents: 'org.apache.bookkeeper.stream.server.StreamStorageLifecycleComponent'  # Needed for Pulsar stateful functions
    zkServers: zookeeper-{{ ENVIRONMENT }}-0-{{ zk_release_id }}.zookeeper.service.consul:2181,zookeeper-{{ ENVIRONMENT }}-1-{{ zk_release_id }}.zookeeper.service.consul:2181,zookeeper-{{ ENVIRONMENT }}-2-{{ zk_release_id }}.zookeeper.service.consul:2181
    permittedStartupUsers: bookkeeper
    ledgerDirectories: /var/opt/bookkeeper-ledger
    journalDirectories: /var/opt/bookkeeper-journal
    ledgerManagerType: hierarchical
