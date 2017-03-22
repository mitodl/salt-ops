# Rollback Micromasters

## Scenario - 3/17/2017
A Micromasters release has a major bug and some action needs to be performed to get things back to normal.

## Workflow
There are three possible workflows to follow based on the scenario above:
1. Rollback the heroku app only
2. Rollback the heroku app and restore the database
3. Release a bug fix

Determining whether to release a bug or rollback is something that will need to be decided on through consultations and a decision made. If it's decided, that a rollback is necessary, then first and foremost, determine by talking to the release manager, whether the release performed any schema changes. If no schema changes were part of the release, then all that is required is a heroku rollback which can be performed by running:
``` heroku releases rollback -a <app name> ```

If however, it's determined that the relase did impact the schema, then the following steps would need to be performed:
- Using Vault, create a read-only PostgreSQL account and change the config vars in the heroku app to use that account in order to prevent future writes.
- Take a snapshot of the existing database prior to rolling it back to a point in time right before the app was released.
- Restore database.
- Rollback heroku app.
- Determine if any data is missing between snapshot and restored database and recover if necessary.