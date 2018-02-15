{% set slack_webhook_url_odl = salt.vault.read('secret-operations/global/slack-odl/slack_webhook_url').data.value %}
{% set slack_webhook_url_devops = salt.vault.read('secret-operations/global/slack/slack_webhook_url').data.value %}
{% set opsgenie_ops_team_api = salt.vault.read('secret-operations/global/opsgenie/opsgenie_ops_team_api').data.value %}
{% set mitca_ssl_cert = salt.vault.read('secret-operations/global/mitca_ssl_cert').data.value %}

elasticsearch:
  lookup:
    elastic_stack: True
    pkgs:
      - apt-transport-https
      - nginx
      - python-openssl
  elastalert:
    overrides:
      settings:
        es_host: nearest-elasticsearch.query.consul
    rules:
      - name: mailgun
        settings:
          name: Mailgun delivery failure
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
          slack_webhook_url: {{ slack_webhook_url_odl }}
          slack_channel_override: "#micromasters-eng"
          slack_username_override: "Elastalert"
          slack_msg_color: "warning"
          filter:
            - bool:
                should:
                  - term:
                      fluentd_tag: mailgun.micromasters.dropped
                  - term:
                      fluentd_tag: mailgun.micromasters.bounced
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
          slack_webhook_url: {{ slack_webhook_url_devops }}
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
          alert_text: "Operational Failure on mitx-production detected"
          slack_webhook_url: {{ slack_webhook_url_devops }}
          slack_channel_override: "#devops"
          slack_username_override: "Elastalert"
          slack_msg_color: "warning"
          filter:
            - bool:
                must:
                  - match:
                      message: Operation Failure
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
          alert_text: "git-reload error on mitx-production detected"
          slack_webhook_url: {{ slack_webhook_url_devops }}
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
          opsgenie_key: {{ opsgenie_ops_team_api }}
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
          alert_text: "<@tmacey> <@shaidar> Rabbitmq AMQPLAIN login refused due to expired vault credentials"
          slack_webhook_url: {{ slack_webhook_url_devops }}
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
          use_count_query: True
          doc_type: fluentd
          alert:
            - slack
          alert_text: "<@tmacey> <@shaidar> The number of messages for tag {0} is outside of the normal bounds"
          alert_text_args:
            - fluentd_tag

kibana:
  lookup:
    nginx_config:
      server.name: logs.odl.mit.edu
      server.ssl.enabled: true
      server.ssl.certificate: /etc/salt/ssl/certs/kibana.odl.mit.edu.crt
      server.ssl.key: /etc/salt/ssl/certs/kibana.odl.mit.edu.key
    nginx_extra_config_list:
      - ssl_client_certificate /etc/salt/ssl/certs/mitca.pem;
      - ssl_verify_client on;
      - set $authorized "no";
      - if ($ssl_client_s_dn ~ "/emailAddress=(tmacey|pdpinch|shaidar|ichuang|gsidebo|mkdavies|gschneel)@MIT.EDU") { set $authorized "yes"; }
      - if ($authorized !~ "yes") { return 403; }
    nginx_extra_files:
      - name: mitca
        path: /etc/salt/ssl/certs/mitca.pem
        contents: |
          {{ mitca_ssl_cert|indent(10) }}
  ssl:
    {% set odl_wildcard = salt.vault.read('secret-operations/global/odl_wildcard_cert') %}
    cert_source: |
      {{ odl_wildcard.data.value|indent(6) }}
    key_source: |
      {{ odl_wildcard.data.key|indent(6) }}

beacons:
  service:
    elasticsearch:
      onchangeonly: True
      interval: 30
    kibana:
      onchangeonly: True
      interval: 30
    nginx:
      onchangeonly: True
      interval: 30
    disable_during_state_run: True
