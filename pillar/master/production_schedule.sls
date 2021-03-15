{% set ONE_WEEK = 604800 %}

schedule:
  backup_edx_rp_data:
    maxrunning: 1
    when: 1:00am
    function: saltutil.runner
    args:
      - state.orchestrate
    kwargs:
      mods: orchestrate.edx.backup
  backup_operations_data:
    maxrunning: 1
    when: 1:00am
    function: saltutil.runner
    args:
      - state.orchestrate
    kwargs:
      mods: orchestrate.operations.backups
  delete_edx_logs_older_than_30_days:
    maxrunning: 1
    when: Sunday 5:00am
    function: state.sls
    args:
      - edx.maintenance_tasks
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
