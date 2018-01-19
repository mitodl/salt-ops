#!yaml

datadog:
  integrations:
    fluentd:
      settings:
        instances:
          - monitor_agent_url: http://127.0.0.1:24220/api/plugins.json
        plugin_ids:
          - es_outbound
          - salt_logs_inbound
          - syslog_inbound
          - heroku_logs_inbound
