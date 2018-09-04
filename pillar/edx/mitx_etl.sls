{% set purpose = salt.grains.get('purpose', 'current-residential-live')%}
{% set purpose_suffix = purpose.replace('-', '_') %}
{% set env = salt.grains.get('environment', 'mitx-qa') %}

mitx_residential_etl:
  settings:
    AWS:
      AWS_ACCESS_KEY_ID: __vault__:cache:aws-mitx/creds/read-write-mitx-etl-{{ purpose }}-{{ env }}>data>access_key
      AWS_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/read-write-mitx-etl-{{ purpose }}-{{ env }}>data>secret_key
    Paths:
      csv_folder: /mnt/data/csv_query_folder
      courses: /mnt/data/mitx_etl/courses
    MySQL:
      user: __vault__:cache:mysql-{{ env }}/creds/admin>data>username
      pass: __vault__:cache:mysql-{{ env }}/creds/admin>data>password
      host: mysql.service.consul
      db: edxapp_{{ purpose_suffix }}
    Slack:
      bot_username: mitx_residential_etl_bot
      bot_emoji: ":gear:"
      webhook_url: __vault__::secret-operations/global/slack/slack_webhook_url>data>value
    Logs:
      logfile: /edx/var/log/mitx_residential_etl.log
      max_size: 1048576
      backup_count: 12
      level: 4
    S3Bucket:
      bucket: mitx-etl-{{ purpose }}-{{ env }}
