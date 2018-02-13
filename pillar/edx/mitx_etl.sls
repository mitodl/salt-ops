{% set purpose = salt.grains.get('purpose', 'current-residential-live')%}
{% set purpose_suffix = purpose.replace('-', '_') %}
{% set env = salt.grains.get('environment', 'mitx-qa') %}
{% set AWS_CREDS = salt.vault.read('aws-mitx/creds/read-write-mitx-etl-{}-{}'.format(purpose, env)) %}
{% set slack_webhook_url_devops = salt.vault.read('secret-operations/global/slack/slack_webhook_url').data.value %}
{% set edxapp_mysql_creds = salt.vault.read('mysql-{}/creds/admin'.format(env)) %}

mitx_residential_etl:
  settings:
    AWS:
      AWS_ACCESS_KEY_ID: {{ AWS_CREDS.data.access_key }}
      AWS_SECRET_ACCESS_KEY: {{ AWS_CREDS.data.secret_key }}
    Paths:
      csv_folder: /mnt/data/csv_query_folder
    MySQL:
      user: {{ edxapp_mysql_creds.data.username }}
      pass: {{ edxapp_mysql_creds.data.password }}
      host: mysql.service.consul
      db: edxapp_{{ purpose_suffix }}
    Slack:
      bot_username: mitx_residential_etl_bot
      bot_emoji: ":gear:"
      webhook_url: {{ slack_webhook_url_devops }}
    Logs:
      logfile: /edx/var/log/mitx_residential_etl.log
      max_size: 1048576
      backup_count: 12
      level: 4
    S3Bucket:
      bucket: mitx-etl-{{ purpose }}-{{ env }}
