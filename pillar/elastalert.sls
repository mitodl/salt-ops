{% set mailgun_apps = {
    'micromasters': 'mailgun-eng',
    'discussions': 'mailgun-eng'} %}
{% set slack_webhook_url = '__vault__::secret-operations/global/slack-odl/slack_webhook_url>data>value' %}

elasticsearch:
  elastalert:
    overrides:
      settings:
        es_host: nearest-elasticsearch.query.consul
    rules:
    {% for app,slack_channel in mailgun_apps.items() %}
      - name: mailgun-{{ app }}
        settings:
          name: Mailgun {{ app }} delivery failure
          description: >-
            Send a message for any email delivery failures so that they
            are visible and can be evaluated to determine any common
            causes that may suggest potential fixes.
          type: frequency
          index: logstash-*
          num_events: 1
          timeframe:
            minutes: 15
          alert:
            - slack
          alert_text: "Email delivery via Mailgun failed."
          slack_webhook_url: {{ slack_webhook_url }}
          slack_channel_override: "#{{ slack_channel }}"
          slack_username_override: "Elastalert"
          slack_msg_color: "warning"
          filter:
            - bool:
                should:
                  - term:
                      fluentd_tag: mailgun.{{ app }}.dropped
                  - term:
                      fluentd_tag: mailgun.{{ app }}.bounced
    {% endfor %}
      - name: ssh_mitx
        settings:
          name: SSH events on mitx instances
          description: >-
            Send a message anytime an ssh session is established on any
            of the mitx instances so that it can be further investigated.
          type: frequency
          index: logstash-*
          num_events: 1
          timeframe:
            minutes: 5
          alert:
            - slack
          alert_text: "SSH session detected"
          slack_webhook_url: __vault__::secret-operations/global/slack/slack_webhook_url>data>value
          slack_channel_override: "#devops"
          slack_username_override: "Elastalert"
          slack_msg_color: "warning"
          filter:
            - bool:
                must:
                  - match:
                      message: session opened
                  - term:
                      environment.raw: mitx-production
                  - term:
                      fluentd_tag.raw: syslog.auth
                  - term:
                      ident: sshd
                must_not:
                  - match:
                      message: ichuang
      - name: mitx_operational_failure
        settings:
          name: Operational Failure on mitx instances
          description: >-
            Send a message anytime an 'Operational Failure' message is
            encountered in the mitx production logs.
          type: frequency
          index: logstash-*
          num_events: 1
          timeframe:
            minutes: 5
          alert:
            - slack
          alert_text: "<!subteam^S9PK3B39V|devopseng> Operational Failure on mitx-production detected"
          slack_webhook_url: {{ slack_webhook_url }}
          slack_channel_override: "#mitx-eng"
          slack_username_override: "Elastalert"
          slack_msg_color: "warning"
          filter:
            - bool:
                must:
                  - match:
                      message: OperationFailure
                  - term:
                      environment.raw: mitx-production
      - name: mitx_gitreload_slack_alert
        settings:
          name: git reload error on mitx instances - slack
          description: >-
            Send a message anytime an error message containing git_import.py or
            git_export_utils.py is encountered in the mitx production logs.
          type: frequency
          index: logstash-*
          num_events: 1
          timeframe:
            minutes: 5
          alert:
            - slack
          alert_text: "<!subteam^S9PK3B39V|devopseng> git-reload error on mitx-production detected"
          slack_webhook_url: {{ slack_webhook_url }}
          slack_channel_override: "#devops"
          slack_username_override: "Elastalert"
          slack_msg_color: "warning"
          filter:
            - bool:
                should:
                  - term:
                      filename: git_import.py
                  - term:
                      filename: git_export_utils.py
                must:
                  - term:
                      log_level: ERROR
                  - term:
                      environment.raw: mitx-production
      - name: mitx_gitreload_opsgenie_alert
        settings:
          name: git reload error on mitx instances - opsgenie
          description: >-
            Send a message anytime an error message containing git_import.py or
            git_export_utils.py is encountered in the mitx production logs.
          opsgenie_key: __vault__::secret-operations/global/opsgenie/opsgenie_ops_team_api>data>value
          type: frequency
          index: logstash-*
          num_events: 5
          timeframe:
            hours: 1
          alert:
            - opsgenie
          alert_text: "git-reload error on mitx-production detected"
          filter:
            - bool:
                should:
                  - term:
                      filename: git_import.py
                  - term:
                      filename: git_export_utils.py
                must:
                  - term:
                      log_level: ERROR
                  - term:
                      environment.raw: mitx-production
      - name: rabbitmq_creds_expired
        settings:
          name: Rabbitmq AMQPLAIN login refused
          description: >-
            Send a message anytime an 'AMQPLAIN login refused' message is
            encountered in the rabbitmq.server logs due to expired vault credentials.
          type: frequency
          index: logstash-*
          num_events: 1
          timeframe:
            minutes: 5
          alert:
            - slack
          alert_text: "<!subteam^S9PK3B39V|devopseng> Rabbitmq AMQPLAIN login refused due to expired vault credentials"
          slack_webhook_url: {{ slack_webhook_url }}
          slack_channel_override: "#devops"
          slack_username_override: "Elastalert"
          slack_msg_color: "warning"
          filter:
            - bool:
                must:
                  - match:
                      message: AMQPLAIN login refused
                  - match:
                      type: ERROR
                  - term:
                      fluentd_tag: rabbitmq.server
      - name: fluent_s3_error
        settings:
          name: FluentD server S3 credentials
          description: >-
            Notify when the IAM credentials for FluentD are expired
          type: frequency
          index: logstash-*
          num_events: 1
          timeframe:
            minutes: 30
          alert:
            - slack
          alert_text: >-
             <!subteam^S9PK3B39V|devopseng> The IAM credentials for the FluentD servers to ship
             to S3 have expired and need to be regenerated.
          slack_webhook_url: {{ slack_webhook_url }}
          slack_channel_override: "#devops"
          slack_username_override: "Elastalert"
          slack_msg_color: "warning"
          filter:
            - bool:
                must:
                  - match:
                      message: failed to flush the buffer
                  - match:
                      error: 'Aws::S3::Errors::Forbidden'
                  - term:
                      fluentd_tag: fluent.warn
      - name: log_volume_spike
        settings:
          name: Alert for change in volume of logs
          description: >-
              Notify for any time that the volume of logs for a particular
              log source is outside of normal bounds
          type: spike
          index: logstash-*
          query_key: fluentd_tag
          alert_on_new_data: False
          spike_type: both
          spike_height: 2
          timeframe:
            minutes: 30
          threshold_ref: 50
          use_count_query: True
          doc_type: fluentd
          alert:
            - slack
          alert_text: "<!subteam^S9PK3B39V|devopseng> The number of messages for tag {0} is outside of the normal bounds"
          alert_text_args:
            - fluentd_tag
          slack_webhook_url: {{ slack_webhook_url }}
          slack_channel_override: "#devops"
          slack_username_override: "Elastalert"
          slack_msg_color: "warning"
      - name: nginx_bad_gateway
        settings:
          name: Alert on bad gateway errors from Nginx
          description: >-
            Notify for occurrences of 502 errors on applications that use Nginx to proxy requests to an upstream
            process
          type: frequency
          index: logstash-*
          num_events: 1
          timeframe:
            minutes: 5
          alert:
            - slack
          alert_text: >-
            <!subteam^S9PK3B39V|devopseng> The upstream service on {0} is not responding to Nginx
          alert_text_args:
            - minion_id
          slack_webhook_url: {{ slack_webhook_url }}
          slack_channel_override: "#devops"
          slack_username_override: Elastalert
          slack_msg_color: warning
          filter:
            - bool:
                must:
                  - wildcard:
                      fluentd_tag: '*.nginx.*'
                  - term:
                      status: 502
