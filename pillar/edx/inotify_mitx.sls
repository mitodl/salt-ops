beacons:
  inotify:
    - files:
        /lib:
          recurse: True
          auto_add: True
        /bin:
          recurse: True
          auto_add: True
        /sbin:
          recurse: True
          auto_add: True
        /boot:
          recurse: True
          auto_add: True
        /lib64:
          recurse: True
          auto_add: True
        /usr:
          recurse: True
          auto_add: True
        /edx:
          exclude:
            - /edx/var/log
            - /edx/var/edxapp/export_course_repos
            - /edx/app/edxapp/venvs/edxapp-sandbox/.config/matplotlib
          recurse: True
          auto_add: True
        /opt:
          exclude:
            - /opt/datadog-agent/run
            - /opt/datadog-agent/agent
          recurse: True
          auto_add: True
        /etc:
          exclude:
            - /etc/cas/timestamp
            - /etc/salt/gpgkeys/random_seed
          recurse: True
          auto_add: True
        /var:
          exclude:
            - /var/backups
            - /var/cache
            - /var/log
            - /var/lib
            - /var/lock
            - /var/mail
            - /var/spool
            - /var/tmp
          recurse: True
          auto_add: True
