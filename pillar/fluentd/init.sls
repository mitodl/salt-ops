fluentd:
  overrides:
    version: "1.8.0"
    user: root
    group: root

beacons:
  service:
    - services:
        fluentd:
          onchangeonly: True
          delay: 60
          disable_during_state_run: True
    - interval: 60
