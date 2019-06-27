edxapp_highstate:
  local.state.sls:
    - tgt: {{ data['id'] }}
    - queue: True
    - arg:
        - edx.prod
    - kwargs:
        pillar:
          edx:
            ansible_flags: '--tags install:configuration'
