schedule:
  delete_edx_logs_older_than_30_days:
    maxrunning: 1
    when: Sunday 5:00am
    function: state.sls
    args:
      - edx.maintenance_tasks