monit_app:
  notification: 'slack'
  modules:
    latex2edx:
      host:
        custom:
          name: studio-input-filter.mitx.mit.edu
        with:
          address: studio-input-filter.mitx.mit.edu
        if:
          failed: port 443 protocol https request "/latex2edx?raw=1" status = 200
          action: exec "/bin/sh -c /usr/local/bin/slack.sh"
