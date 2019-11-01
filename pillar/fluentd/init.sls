fluentd:
  overrides:
    version: "1.1.1"
    user: root
    group: root
  plugins:
    - fluent-plugin-secure-forward

beacons:
  service:
    - services:
        fluentd:
          onchangeonly: True
          delay: 60
          disable_during_state_run: True
    - interval: 60
