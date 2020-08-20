{% set salt_master_internal_ip = salt.saltutil.runner('mine.get',
                                                      tgt='master*',
                                                      fun='network.ip_addrs') %}

salt_master:
  extra_configs:
    returner:
      master_job_cache: pgjsonb
      event_return: pgjsonb
      returner.pgjsonb.host: operations-rds-postgres-saltmaster.cbnm7ajau6mi.us-east-1.rds.amazonaws.com
      returner.pgjsonb.port: 5432
      returner.pgjsonb.user: __vault__:cache:postgres-operations-saltmaster/creds/saltmaster>data>username
      returner.pgjsonb.pass: __vault__:cache:postgres-operations-saltmaster/creds/saltmaster>data>password
      returner.pgjsonb.db: saltmaster
      returner.pgjsonb.sslmode: verify-full
      returner.pgjsonb.sslrootcert: /usr/local/share/ca-certificates/rds-ca-2019.crt
