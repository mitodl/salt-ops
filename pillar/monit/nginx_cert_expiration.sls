monit_app:
  modules:
    nginx_cert_expiration:
      host:
        custom:
          name: nginx.service
        with:
          address: localhost
        if:
          failed: port 443 protocol https request "/heartbeat" status = 200 and certificate valid > 30 days
          action: exec "/bin/sh -c /usr/local/bin/slack.sh"
