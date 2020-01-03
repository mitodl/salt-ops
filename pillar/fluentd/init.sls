fluentd:
  overrides:
    version: "1.8.0"
    user: root
    group: root
  pki:
    ca_chain:
      content: __vault__::secret-operations/global/pki/ca_chain>data>value
      path: '/usr/local/share/ca-certificates/ca_chain.crt'

beacons:
  service:
    - services:
        fluentd:
          onchangeonly: True
          delay: 60
          disable_during_state_run: True
    - interval: 60
