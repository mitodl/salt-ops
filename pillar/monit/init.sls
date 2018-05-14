monit_app:
  notification: 'slack'
  slack_webhook_url: __vault__::secret-operations/global/slack/slack_mitx_eng_alerts>data>value
