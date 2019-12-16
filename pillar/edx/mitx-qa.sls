edx:
  gitreload:
    basic_auth:
      username: mitx
      password: __vault__::secret-residential/mitx-qa/gitreload>data>value
  ansible_vars:
    EDXAPP_CAS_SERVER_URL: 'https://auth.mitx.mit.edu/cas'
