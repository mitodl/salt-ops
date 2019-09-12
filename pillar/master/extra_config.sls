salt_master:
  extra_configs:
    returner:
      master_job_cache: pgjsonb
      event_return: pgjsonb
      returner.pgjsonb.host: postgres-saltmaster.service.consul
      returner.pgjsonb.port: 5432
      returner.pgjsonb.user: __vault__:cache:postgres-operations-saltmaster/creds/saltmaster>data>username
      returner.pgjsonb.pass: __vault__:cache:postgres-operations-saltmaster/creds/saltmaster>data>password
      returner.pgjsonb.db: saltmaster
