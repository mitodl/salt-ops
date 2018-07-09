monit_app:
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
          failed: port 443 protocol https request "/heartbeat" status = 200 and certificate valid > 30 days
          action: exec "/bin/sh -c /usr/local/bin/slack.sh"
