{% set slack_webhook_url_devops = salt.vault.read('secret-operations/global/slack-odl/slack_webhook_url').data.value %}

monit_app:
  notification: 'slack'
  slack_webhook_url: {{ slack_webhook_url_devops }}
  modules:
    nginx_cert_expiration:
      process:
        custom:
          name: nginx
        with:
          pidfile: /var/run/nginx.pid
        config:
          group: www
          start: "/etc/init.d/nginx start"
          stop: "/etc/init.d/nginx stop"
        if:
          failed: port 443 protocol https and certificate valid > 30 days
          action: exec "/bin/sh -c /usr/local/bin/slack.sh"
