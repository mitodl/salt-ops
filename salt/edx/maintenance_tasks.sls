delete_edx_logs_older_than_30_days:
  cmd.run:
    - name: >-
        find /edx/var/log -not -path "/edx/var/log/tracking/*"
        -type f \( -name "*.gz" -o -name "lms-stderr.log.*" \)
        -mtime +30 -delete
