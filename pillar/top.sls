base:
  '*':
    - common
  'roles:master':
    - match: grain
    - master
  'G@roles:devstack and P@environment:dev':
    - match: compound
    - devstack
    - mysql_devstack
