# Background
MITx Residential upgrade typically takes place twice a year following OpenedX's named releases and happens between school semesters. To manage the upgrade, Devops has to perform a few taks before and during and scheduled maintancne window outlined below.

## Several days prior to upgrade

#### Communication
- Once a date and time for the downtime is finalized, send request to post scheduled downtime to 3down. Here's an example of the message:
    + The Residential MITx system (lms.mitx.mit.edu, studio.mitx.mit.edu and staging.mitx.mit.edu) will be unavailable starting at `<time>` for an estimated `<time>` hours while we perform routine upgrades. If you have any questions please contact mitx-support@mit.edu
- Update S3 `upgrading.mitx.mit.edu` bucket maintenance html page to reflect maintenance time

### Tech prep
- Build edxapp and worker AMIs
- Deploy EC2 instances from AMIs
- Smoke-test deployed instances
- Shutdown all supervisor services

## Upgrade window
- Post downtime message on the site by updating the DNS entry for lms and studio to point to the CloudFront Distribution that is configured to use the S3 bucket as its origin
- Stop all edX processes on the current instances
- Run migrations on new instances
- Start all edX processes on the new instances
- Add new instances to ELB
- Remove old instances from ELB
- Verify that site is up and functional by running some manual tests
- Change DNS back to point to ELB
