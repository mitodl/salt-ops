schedule:
  delete_edx_logs_older_than_30_days:
    maxrunning: 1
    when: Sunday 5:00am
    function: state.sls
    args:
      - edx.maintenance_tasks
  {% if 'edx-worker' in salt.grains.get('roles') %}
  restart_edx_worker_services:
    days: 5
    splay: 30
    function: supervisord.restart
    args:
      - all
    kwargs:
      bin_env: /edx/bin/supervisorctl
  {% endif %}