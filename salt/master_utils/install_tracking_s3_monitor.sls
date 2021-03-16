
install_monitor_script:
  file.managed:
    - name: /usr/local/sbin/check-s3-tracking-logs.sh
    - contents: |
        #!/usr/bin/env bash
        BUCKETS="odl-residential-tracking-data"
        # -e means fail the script on error ...
        set -e
        today=`date +"%F"`
        for bucket in $BUCKETS; do
            # ... and this will return error status for no matching objects:
            aws s3 ls s3://$bucket/logs/$today
        done
        curl -s '{{ __vault__::secret-operations/global/healthchecks/mitx-tracking-s3>data>value }}'
    - mode: '0755'

monitor_script_cronjob:
  cron.present:
    - identifier: check_tracking_logs
    - name: /usr/local/sbin/check-s3-tracking-logs.sh
    - user: root
    - minute: 0
    - hour: 11
