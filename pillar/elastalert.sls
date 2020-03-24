{% set mailgun_apps = {
    'micromasters': 'mailgun-eng',
    'discussions': 'mailgun-eng'} %}
{% set slack_webhook_url = '__vault__::secret-operations/global/slack-odl/slack_webhook_url>data>value' %}
{% set opsgenie_key = ' __vault__::secret-operations/global/opsgenie/opsgenie_ops_team_api>data>value' %}

elastic_stack:
  elastalert:
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
          opsgenie_alias: ssh_mitx
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
      - name: edx_operational_failure
        settings:
          name: Operational Failure on MITx or xPRO instances
          description: >-
            Send a message anytime an 'Operational Failure' message is
            encountered in the MITx or xPRO production logs.
          opsgenie_key: {{ opsgenie_key }}
          opsgenie_priority: P1
          opsgenie_alias: edx_operational_failure
          type: frequency
          index: logstash-*
          num_events: 1
          timeframe:
            minutes: 5
          alert:
            - opsgenie
          alert_text: "Operational Failure on mitx or xpro production detected"
          filter:
            - bool:
                must:
                  - match:
                      message: OperationFailure
                should:
                  - term:
                      environment.raw: mitx-production
                  - term:
                      environment.raw: mitxpro-production
      - name: mitx_gitreload_alert
        settings:
          name: git reload error on mitx instances - opsgenie
          description: >-
            Send a message anytime an error message containing git_import.py or
            git_export_utils.py is encountered in the mitx production logs.
          opsgenie_key: {{ opsgenie_key }}
          opsgenie_priority: P3
          opsgenie_alias: mitx_gitreload_alert
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
      - name: mitx_saml_error
        settings:
          name: Authentication with MIT Kerberos is currently unavailable
          description: >-
            Send a message anytime an error message containing No SAMLProviderData
            found is encountered in the mitx production logs.
          opsgenie_key: {{ opsgenie_key }}
          opsgenie_priority: P1
          opsgenie_alias: mitx_saml_error
          type: frequency
          index: logstash-mitx-*
          num_events: 1
          timeframe:
            hours: 1
          alert:
            - opsgenie
          alert_text: >-
            Authentication with MIT Kerberos is currently unavailable.
            Need to run manage.py saml pull on residential instance to
            update metadate.
          filter:
            - bool:
                must:
                  - match:
                      message.raw: No SAMLProviderData found
                  - term:
                      fluentd_tag.raw: edx.lms
                should:
                  - term:
                      environment.raw: mitx-production
      - name: edx_multiple_forum_roles
        settings:
          name: Multiple Forum roles on MITx or xPRO instances
          description: >-
            Send a message anytime a 'Multiple Forum roles' message is
            encountered in the MITx or xPRO production logs.
          opsgenie_key: {{ opsgenie_key }}
          opsgenie_priority: P3
          opsgenie_alias: edx_multiple_forum_roles
          type: frequency
          index: logstash-*
          num_events: 1
          timeframe:
            minutes: 5
          alert:
            - opsgenie
          alert_text: "Multiple Forum roles on mitx or xpro production detected"
          filter:
            - bool:
                must:
                  - match:
                      message.raw: returned more than one Role
                  - term:
                      fluentd_tag.raw: edx.lms
                should:
                  - term:
                      environment.raw: mitx-production
                  - term:
                      environment.raw: mitxpro-production
      - name: edx_session_save_failure
        settings:
          name: MITx or xPRO could not save its session
          description: >-
            The call to request.session.save() failed in
            django.contrib.sessions.middleware.py, usually as the result of
            not being able to write to the Memcache layer.
          opsgenie_key: {{ opsgenie_key }}
          opsgenie_priority: P2
          opsgenie_alias: edx_session_save_failure
          type: frequency
          index: logstash-*
          num_events: 1
          timeframe:
            minutes: 5
          alert:
            - opsgenie
          alert_text: "MITx or xPRO could not save its session (Memcache failure)"
          filter:
            - bool:
                must:
                  - match:
                      message: session was deleted before the request completed
                  - term:
                      environment.raw: mitx*
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
          opsgenie_alias: rabbitmq_creds_expired
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
          opsgenie_alias: fluent_s3_error
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
          opsgenie_alias: nginx_bad_gateway
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
      - name: xpro_openedx_oauth2error
        settings:
          name: xPRO openedx account provisioning failed
          description: >-
            xPRO openedx account provisioning failed.
            Might need to check configs and verify that
            there no mismatches
          opsgenie_key: {{ opsgenie_key }}
          opsgenie_priority: P3
          opsgenie_alias: xpro_openedx_oauth2error
          type: frequency
          index: logstash-*
          num_events: 1
          timeframe:
            minutes: 5
          alert:
            - opsgenie
          alert_text: "xPRO openedx account provisioning failed"
          filter:
            - bool:
                must:
                  - match:
                      message: courseware.exceptions.OpenEdXOAuth2Error
                  - term:
                      fluentd_tag.raw: heroku.xpro
      - name: xpro_jwt_error
        settings:
          name: xPRO potential misconfigured JWT
          description: >-
            xPRO openedx instances appear to have
            misconfigured JWT keys under lms.env.json
          opsgenie_key: {{ opsgenie_key }}
          opsgenie_priority: P2
          opsgenie_alias: xpro_jwt_error
          type: frequency
          index: logstash-mitxpro-*
          num_events: 1
          timeframe:
            minutes: 5
          alert:
            - opsgenie
          alert_text: "xPRO openedx instances might have misconfigured JWT keys"
          filter:
            - query:
                query_string:
                  query: "environment.raw: mitxpro-production AND fluentd_tag.raw: edx.lms"
            - query:
                query_string:
                  query: "message: ValueError AND JSON AND decoded"
      - name: ocw_invalid_literal_for_int
        settings:
          name: OCW CMS needs restart for invalid literal for int() error
          description: >-
            The OCW CMS needs to be restarted to get rid of server errors saying
            "invalid literal for int()," which we believe are due to resource
            overconsumption -- memory or disk cache.
          opsgenie_key: {{ opsgenie_key }}
          opsgenie_priority: P3
          opsgenie_alias: ocw_invalid_literal_for_int
          type: frequency
          index: logstash-ocw-*
          num_events: 1
          timeframe:
            minutes: 5
          alert:
            - opsgenie
          alert_text: "OCW CMS needs restart for invalid literal for int() error"
          filter:
            - bool:
                must:
                  - query_string:
                      default_field: message
                      query: error AND invalid AND literal AND int
                filter:
                  - term:
                      fluentd_tag: ocwcms.zope.event
      - name: ocw_media_asset_error
        settings:
          name: OCW exception processing media asset
          description: >-
            There was an exception processing a media asset on an OCW page.
            In the past, this has been because of incorrectly-named media
            assets. The error has been generated typically by the
            media_background_image_urls_mapping endpoint that is requested by
            the mirror engine.
          type: frequency
          index: logstash-ocw-*
          num_events: 1
          timeframe:
            minutes: 5
          alert:
            - slack
          alert_text: "OCW exception processing media asset"
          slack_webhook_url: {{ slack_webhook_url }}
          slack_channel_override: '#ocw-eng'
          slack_username_override: Elastalert
          slack_msg_color: "warning"
          filter:
            - bool:
                must:
                  - query_string:
                      default_field: message
                      query: MediaAndBackgroundImagesURLView AND mediaAsset
                filter:
                  - term:
                      fluentd_tag: ocwcms.zope.event
      - name: mitx_git_export_failure
        settings:
          name: Automated git export failure
          description: >-
            An exception was encountered from the edX application when exporting
            a course to git.
          type: frequency
          index: logstash-mitx*-production*
          num_events: 1
          timeframe:
            minutes: 5
          alert:
            - slack
          alert_text: "Automated git export failure"
          slack_webhook_url: {{ slack_webhook_url }}
          slack_channel_override: '#mitx-tech-notifs'
          slack_username_override: Elastalert
          slack_msg_color: "warning"
          filter:
            - bool:
                must:
                  - query_string:
                      default_field: message
                      query: error AND export_git
                filter:
                  - term:
                      fluentd_tag: edx.cms
      - name: edx_s3_response_error
        settings:
          name: edX S3 Response Error
          description: >-
            An edX worker got an error from S3 while trying to export course
            content to Git. This may mean that the process needs to be
            restarted, or the credentials might need to be refreshed.
          index: logstash-mitx*-production*
          type: frequency
          num_events: 1
          timeframe:
            minutes: 5
          alert:
            - slack
          alert_text: "Automated git export failure"
          slack_webhook_url: {{ slack_webhook_url }}
          slack_channel_override: '#mitx-tech-notifs'
          slack_username_override: Elastalert
          slack_msg_color: "warning"
          filter:
            - bool:
                must:
                  - query_string:
                      default_field: message
                      query: S3ResponseError
                filter:
                  - term:
                      fluentd_tag: edx.cms.stderr
      - name: edx_unregistered_task
        settings:
          name: edX task failing
          description: >-
            A task has failed due to a mismatch in the source code between the
            app and worker node.
          type: frequency
          index: logstash-mitx*-production*
          num_events: 1
          timeframe:
            minutes: 5
          alert:
            - opsgenie
          opsgenie_key: {{ opsgenie_key }}
          opsgenie_priority: P3
          opsgenie_alias: edx_unregistered_task
          alert_text: "Source code mismatch between edX app and worker nodes"
          filter:
            - bool:
                must:
                  - query_string:
                      default_field: message
                      query: (received unregistered task) AND (message has been ignored)
