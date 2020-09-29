edx:
  gitreload:
    basic_auth:
      username: mitx
      password: __vault__::secret-residential/mitx-qa/gitreload>data>value
  dependencies:
    os_packages:
      - git
      - libmysqlclient-dev
      - mariadb-client-10.0
      - landscape-common
      - libssl-dev
      - python3.5
      - python3.5-dev
      - python-pip
      - python3-pip
      - python-virtualenv
      - nfs-common
      - postfix
