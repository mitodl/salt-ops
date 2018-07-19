| Source                          | Environment        | Trigger                                   | Slack                  | Schedule |
| --------------------------------| ------------------ | ----------------------------------------- | ---------------------- | ---------|
| elastalert                      |                    | mailgun                                   | mailgun-eng            |          |
| elastalert                      | residential        | ssh access                                | devops-alerts          |          |
| elastalert                      | residential        | gitreload                                 | devops-alerts          |          |
| elastalert                      | residential        | ops failure                               | devops-alerts          |          |
| elastalert                      | residential        | forum roles                               | devops-alerts          |          |
| elastalert                      |                    | rabbit creds                              | devops-alerts          |          |
| elastalert                      | residential        | fluentd creds                             | devops-alerts          |          |
| elastalert                      |                    | number of messages outside bounds         | devops-notifications   |          |
| elastalert                      |                    | upstream service not responding to Nginx  | devops-alerts          |          |
| lecture-capture-machines        | Win Video          | scheduled script                          | odl-video-service-eng  | nightly  |
| instance(s)                     | residential        | mitx_etl                                  | devops-notifications   |          |
| monit                           | residential        | latex2edx                                 | devops-alerts          |          |
| monit                           | residential        | lms_503                                   | devops-alerts          |          |
| monit                           | residential        | mongodb_connection                        | devops-alerts          |          |
| monit                           | residential        | mysql_connection                          | devops-alerts          |          |
| monit                           | residential        | nginx_cert_expiration                     | devops-notificaitons   |          |
| datadog                         |                    | high load                                 | devops-notifications   |          |
| datadog                         |                    | low mem                                   | devops-alerts          |          |
| datadog                         |                    | low disk                                  | devops-alerts          |          |
| datadog                         |                    | fluentd unable to ship                    | devops-alerts          |          |
| datadog                         | residential        | mongodb primary no available              | devops-alerts          |          |
| datadog                         | residential        | mysql RDS unreachable                     | devops-alerts          |          |
| datadog                         |                    | no log data                               | devops-notifications   |          |
| datadog                         |                    | rabbitmq queue not draining               | devops-notifications   |          |
| salt reactor                    | residential        | inotify - changes detected                | ODLDevops              |          |
| salt reactor                    | reddit             | restart reddit on low memory              | devops-notifications   |          |
| salt reactor                    | vault              | expiring vault leases                     | devops-notifications   | weekly   |
| salt scheduled                  | residental         | scheduled mitx backup - success           | devops-notifications   | nightly  |
| salt scheduled                  | residental         | scheduled mitx backup - failure           | devops-notifications   | nightly  |
| salt scheduled                  |                    | scheduled operations backup - success     | devops-notifications   | nightly  |
| salt scheduled                  |                    | scheduled operations backup - failure     | devops-notifications   | nightly  |
| salt scheduled                  | residential        | scheduled residential restore - success   | devops-notifications   | weekly   |
| salt scheduled                  | residential        | scheduled residential restore - failure   | devops-notifications   | weekly   |
| salt scheduled                  |                    | ami build - success                       | devops-notifications   |          |
| salt scheduled                  |                    | ami build - failure                       | ODLDevops              |          |
