edxapp_highstate:
  local.state.sls:
    - tgt: {{ data['name'] }}
    - queue: True
    - arg:
        - edx.prod
    - kwargs:
        pillar:
          edx:
            ansible_flags: '--tags install:configuration'
