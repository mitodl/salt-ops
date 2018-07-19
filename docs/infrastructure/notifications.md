| Source                          | Environment        | Trigger                                   | Destination            | Schedule | OpsGenie |
| --------------------------------| ------------------ | ----------------------------------------- | ---------------------- | ---------| ---------|
| elastalert                      |                    | mailgun                                   | mailgun-eng            |          |          |
| elastalert                      | residential        | ssh access                                | devops-alerts          |          | P2       |
| elastalert                      | residential        | gitreload                                 | devops-alerts          |          | P3       |
| elastalert                      | residential        | ops failure                               | devops-alerts          |          | P1       |
| elastalert                      | residential        | forum roles                               | devops-alerts          |          | P3       |
| elastalert                      |                    | rabbit creds                              | devops-alerts          |          | P2       |
| elastalert                      | residential        | fluentd creds                             | devops-alerts          |          | P2       |
| elastalert                      |                    | number of messages outside bounds         | devops-notifications   |          | P5       |
| elastalert                      |                    | upstream service not responding to Nginx  | devops-alerts          |          | P1       |
| lecture-capture-machines        | Win Video          | scheduled script                          | odl-video-service-eng  | nightly  |          |
| instance(s)                     | residential        | mitx_etl                                  | devops-notifications   |          |          |
| monit                           | residential        | latex2edx                                 | mitx-eng-alerts        |          |          |
| monit                           | residential        | lms_503                                   | mitx-eng-alerts        |          |          |
| monit                           | residential        | mongodb_connection                        | mitx-eng-alerts        |          |          |
| monit                           | residential        | mysql_connection                          | mitx-eng-alerts        |          |          |
| monit                           | residential        | nginx_cert_expiration                     | devops-notificaitons   |          |          |
| datadog                         |                    | high load                                 | devops-alerts          |          | P3       |
| datadog                         |                    | low mem                                   | devops-alerts          |          | P3       |
| datadog                         |                    | low disk                                  | devops-alerts          |          | P3       |
| datadog                         |                    | fluentd unable to ship                    | devops-alerts          |          | P3       |
| datadog                         | residential        | mongodb primary no available              | devops-alerts          |          | P3       |
| datadog                         | residential        | mysql RDS unreachable                     | devops-alerts          |          | P3       |
| datadog                         |                    | no log data                               | devops-alerts          |          | P3       |
| datadog                         |                    | rabbitmq queue not draining               | devops-alerts          |          | P3       |
| salt reactor                    | residential        | inotify - changes detected                | ODLDevOps              |          |          |
| salt reactor                    | reddit             | restart reddit on low memory              | devops-notifications   |          | P4       |
| salt reactor                    | vault              | expiring vault leases                     | ODLDevOps              | weekly   |          |
| salt scheduled                  | residential        | scheduled mitx backup - success           | ODLDevOps              | nightly  |          |
| salt scheduled                  | residential        | scheduled mitx backup - failure           | ODLDevOps              | nightly  |          |
| salt scheduled                  |                    | scheduled operations backup - success     | ODLDevOps              | nightly  |          |
| salt scheduled                  |                    | scheduled operations backup - failure     | ODLDevOps              | nightly  |          |
| salt scheduled                  | residential        | scheduled residential restore - success   | ODLDevOps              | weekly   |          |
| salt scheduled                  | residential        | scheduled residential restore - failure   | ODLDevOps              | weekly   |          |
| salt scheduled                  |                    | ami build - success                       | ODLDevOps              |          |          |
| salt scheduled                  |                    | ami build - failure                       | ODLDevOps              |          |          |

Notes:
- Datadog does not have the ability to specify an OpsGenie Priority Level
- Created a few OpsGenie Policies in order to be able to act on priority levels:
  - If priority level is P4 or lower, post to devops-notifications and then automatically close alert
  - If alert contains a `notification` alias set Priority level to P5