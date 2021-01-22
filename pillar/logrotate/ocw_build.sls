logrotate:
  webhook_publish_log:
    name: /opt/ocw/logs/webhook-publish.log
    options:
      - rotate 4
      - daily
      - notifempty
  hugo_www_log:
    name: /opt/ocw/logs/hugo-www.log
    options:
      - rotate 4
      - daily
      - notifempty
  ocw_www_yarn_install_log:
    name: /opt/ocw/logs/ocw-www-yarn-install.log
    options:
      - rotate 4
      - daily
      - notifempty
  ocw_to_hugo_log:
    name: /opt/ocw/logs/ocw-to-hugo.log
    options:
      - rotate 4
      - daily
      - notifempty
  ocw_to_hugo_install_log:
    name: /opt/ocw/logs/ocw-to-hugo-install.log
    options:
      - rotate 4
      - daily
      - notifempty
  ocw_to_hugo_output_sync_log:
    name: /opt/ocw/logs/ocw-to-hugo-output-sync.log
    options:
      - rotate 4
      - daily
      - notifempty
  website_sync_log:
    name: /opt/ocw/logs/website-sync.log
    options:
      - rotate 4
      - daily
      - notifempty
  course_builds_log:
    name: /opt/ocw/logs/course-builds.log
    options:
      - rotate 4
      - daily
      - notifempty
      - compress
      - delaycompress
