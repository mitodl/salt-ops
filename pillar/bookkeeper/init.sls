bookkeeper:
  config:
    extraServerComponents: 'org.apache.bookkeeper.stream.server.StreamStorageLifecycleComponent'  # Needed for Pulsar stateful functions
    zkServers: zookeeper.service.consul:2181
    permittedStartupUsers: bookkeeper
    ledgerDirectories: /var/opt/bookkeeper-ledger
    journalDirectories: /var/opt/bookkeeper-journal
    ledgerManagerType: hierarchical
