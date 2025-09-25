{% set ONE_WEEK = 604800 %}

schedule:
  refresh_master_vault_token:
    maxrunning: 1
    days: 5
    function: vault.renew_token
  refresh_master_configs:
    maxrunning: 1
    days: 21
    function: state.sls
    args:
      - master.config
