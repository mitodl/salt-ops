base:
  '*master*':
    - utils.install_libs
    - consul
    - consul.dns_proxy
    - consul.tests
    - consul.tests.test_dns_setup
    - master
    - master.api
    - master_utils.dns
    - master_utils.libgit
    - master.aws
