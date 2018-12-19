{% set mailgun_apps = {
    'micromasters': 'mailgun-eng',
    'discussions': 'mailgun-eng'} %}
{% set slack_webhook_url = '__vault__::secret-operations/global/slack-odl/slack_webhook_url>data>value' %}
{% set opsgenie_key = ' __vault__::secret-operations/global/opsgenie/opsgenie_ops_team_api>data>value' %}

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
          opsgenie_key: {{ opsgenie_key }}
          opsgenie_priority: P2
          type: frequency
          index: logstash-*
          num_events: 1
          timeframe:
            minutes: 5
          alert:
            - opsgenie
          alert_text: "SSH session detected"
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
          opsgenie_key: {{ opsgenie_key }}
          opsgenie_priority: P1
          type: frequency
          index: logstash-*
          num_events: 1
          timeframe:
            minutes: 5
          alert:
            - opsgenie
          alert_text: "Operational Failure on mitx-production detected"
          filter:
            - bool:
                must:
                  - match:
                      message: OperationFailure
                  - term:
                      environment.raw: mitx-production
      - name: mitx_gitreload_alert
        settings:
          name: git reload error on mitx instances - opsgenie
          description: >-
            Send a message anytime an error message containing git_import.py or
            git_export_utils.py is encountered in the mitx production logs.
          opsgenie_key: {{ opsgenie_key }}
          opsgenie_priority: P3
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
      - name: mitx_multiple_forum_roles
        settings:
          name: Multiple Forum roles on mitx instances
          description: >-
            Send a message anytime a 'Multiple Forum roles' message is
            encountered in the mitx production logs.
          opsgenie_key: {{ opsgenie_key }}
          opsgenie_priority: P3
          type: frequency
          index: logstash-*
          num_events: 1
          timeframe:
            minutes: 5
          alert:
            - opsgenie
          alert_text: "Multiple Forum roles on mitx-production detected"
          filter:
            - bool:
                must:
                  - match:
                      message.raw: returned more than one Role
                  - term:
                      environment.raw: mitx-production
                  - term:
                      fluentd_tag.raw: edx.lms
      - name: rapid_response_xblock_status
        settings:
          name: Rapid Response XBlock status changed
          description: >-
            Send a message anytime a rapid response xblock is
            enabled or disabled.
          type: frequency
          index: logstash-*
          num_events: 1
          timeframe:
            minutes: 5
          alert:
            - slack
          alert_text: "Rapid Response XBlock status changed"
          slack_webhook_url: {{ slack_webhook_url }}
          slack_channel_override: "#mitx-tech-notifs"
          slack_username_override: "Elastalert"
          slack_msg_color: "good"
          filter:
            - bool:
                must:
                  - match:
                      #Request is the same whether xblock is enabled or disabled
                      request.raw: rapid_response_xblock/handler/toggle_block_enabled
                  - term:
                      environment.raw: mitx-production
                  - term:
                      fluentd_tag.raw: edx.nginx.access
      - name: rabbitmq_creds_expired
        settings:
          name: Rabbitmq AMQPLAIN login refused
          description: >-
            Send a message anytime an 'AMQPLAIN login refused' message is
            encountered in the rabbitmq.server logs due to expired vault credentials.
          opsgenie_key: {{ opsgenie_key }}
          opsgenie_priority: P2
          type: frequency
          index: logstash-*
          num_events: 1
          timeframe:
            minutes: 5
          alert:
            - opsgenie
          alert_text: "invalid credentials"
          filter:
            - bool:
                must:
                  - match:
                      message: invalid credentials
                  - match:
                      type: ERROR
                  - term:
                      fluentd_tag: rabbitmq.server
      - name: fluent_s3_error
        settings:
          name: FluentD server S3 credentials
          description: >-
            Notify when the IAM credentials for FluentD are expired
          opsgenie_key: {{ opsgenie_key }}
          opsgenie_priority: P2
          type: frequency
          index: logstash-*
          num_events: 1
          timeframe:
            minutes: 30
          alert:
            - opsgenie
          alert_text: >-
             The IAM credentials for the FluentD servers to ship
             to S3 have expired and need to be regenerated.
          filter:
            - bool:
                must:
                  - match:
                      message: failed to flush the buffer
                  - match:
                      error: 'Aws::S3::Errors::Forbidden'
                  - term:
                      fluentd_tag: fluent.warn
      # - name: log_volume_spike
      #   settings:
      #     name: Alert for change in volume of logs
      #     description: >-
      #         Notify for any time that the volume of logs for a particular
      #         log source is outside of normal bounds
      #     opsgenie_key: {{ opsgenie_key }}
      #     opsgenie_priority: P5
      #     type: spike
      #     index: logstash-*
      #     query_key: fluentd_tag
      #     alert_on_new_data: False
      #     spike_type: both
      #     spike_height: 2
      #     timeframe:
      #       minutes: 30
      #     threshold_ref: 50
      #     use_count_query: True
      #     doc_type: fluentd
      #     alert:
      #       - opsgenie
      #     alert_text: "The number of messages for tag {0} is outside of the normal bounds"
      #     alert_text_args:
      #       - fluentd_tag
      - name: nginx_bad_gateway
        settings:
          name: Alert on bad gateway errors from Nginx
          description: >-
            Notify for occurrences of 502 errors on applications that use Nginx to proxy requests to an upstream
            process
          opsgenie_key: {{ opsgenie_key }}
          opsgenie_priority: P1
          type: frequency
          index: logstash-*
          num_events: 5
          timeframe:
            minutes: 5
          alert:
            - opsgenie
          alert_text: >-
            The upstream service on {0} is not responding to Nginx
          alert_text_args:
            - minion_id
          filter:
            - bool:
                must:
                  - wildcard:
                      fluentd_tag: '*.nginx.*'
                  - term:
                      status: 502
