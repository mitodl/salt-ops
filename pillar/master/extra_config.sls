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
  aws:
    providers:
      - name: mitx
        id: use-instance-role-credentials
        key: use-instance-role-credentials
        keyname: salt-master-prod
        private_key_path: /etc/salt/keys/aws/salt-master-prod.pem
        extra_params:
          script_args: -U -F -A salt.private.odl.mit.edu
          sync_after_install: all
          delete_ssh_keys: True
      - name: mitx-stage
        id: __vault__::secret-operations/global/mitx-staging-iam-credentials>data>id
        key: __vault__::secret-operations/global/mitx-staging-iam-credentials>data>secret_key
        keyname: salt-master-stage
        private_key_path: /etc/salt/keys/aws/salt-master-stage.pem
        region: us-west-2
        extra_params:
          script_args: -U -P
          sync_after_install: all
          delete_ssh_keys: True
