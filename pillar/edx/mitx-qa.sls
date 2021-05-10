edx:
  gitreload:
    basic_auth:
      username: mitx
      password: __vault__::secret-residential/mitx-qa/gitreload>data>value
  dependencies:
    os_packages:
      - git
      - libmysqlclient-dev
      - mariadb-client-10.3
      - landscape-common
      - libssl-dev
      - python3-pip
      - python3-virtualenv
      - nfs-common
      - postfix
