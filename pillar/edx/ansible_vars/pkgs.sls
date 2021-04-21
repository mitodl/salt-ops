edx:
  dependencies:
    os_packages:
      - libmysqlclient-dev
      - mariadb-client
      - landscape-common
      - libssl-dev
      - python3-dev
      - python3-pip
      - python3-virtualenv
      - nfs-common
      - postfix
      - memcached
  ansible_vars:
    EDXAPP_PYTHON_VERSION: python3.8
    edxapp_sandbox_python_version: python3.8
