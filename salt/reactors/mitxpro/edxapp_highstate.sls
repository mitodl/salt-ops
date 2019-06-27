edxapp_highstate:
  local.state.apply:
    - tgt: {{ data['name'] }}
    - queue: True
    - kwargs:
        pillar:
          edx:
            ansible_flags: '--tags install:configuration'
