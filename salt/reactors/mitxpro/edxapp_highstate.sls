edxapp_highstate:
  local.state.apply:
    - tgt: 'edx-*mitxpro-production-xpro-production-*'
    - queue: True
    - kwargs:
        pillar:
          edx:
            ansible_flags: '--tags install:configuration'
