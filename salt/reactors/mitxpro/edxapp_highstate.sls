edxapp_highstate:
  local.state.apply:
    - tgt: 'edx-*mitxpro-production-xpro-production-*'
    - queue: True
