base:
  'master*':
    - master
    - master.schedule
    - master.config
    - common
    - environment_settings
    - fluentd
    - vault
    - vault.roles.apps
    - vault.roles.aws
    - vault.roles.bootcamps
    - vault.roles.micromasters
    - vault.roles.mitx
    - vault.roles.operations
