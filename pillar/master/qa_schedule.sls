{% set ONE_WEEK = 604800 %}

schedule:
  scan_for_expiring_vault_leases:
    maxrunning: 1
    when: Monday 9:00am
    function: vault.scan_leases
    kwargs:
      time_horizon: {{ ONE_WEEK }}
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
  restore_edx_qa_data:
    maxrunning: 1
    when: Monday 1:00pm
    function: saltutil.runner
    args:
      - state.orchestrate
    kwargs:
      mods: orchestrate.edx.restore
