fluentd:
  overrides:
    version: "1.1.1"
  plugins:
    - fluent-plugin-secure-forward

beacons:
  service:
    fluentd:
      onchangeonly: True
    disable_during_state_run: True
