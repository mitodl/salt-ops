monit_app:
  modules:
    lms_503:
      host:
        custom:
          name: lms.mitx.mit.edu
        with:
          address: lms.mitx.mit.edu
        if:
          failed: port 443 protocol https request "/heartbeat" status = 200
          action: exec "/bin/sh -c /usr/local/bin/slack.sh"
