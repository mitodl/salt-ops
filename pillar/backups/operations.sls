#!jinja|yaml|gpg

{% set ENVIRONMENT = salt.grains.get('environment') %}

backups:
  enabled:
    - title: elasticsearch-operations
      name: elasticsearch
      pkgs:
        - curl
      settings:
        snapshot_repository_name: operations_es_backup
        healthcheck_url: __vault__::secret-operations/global/healthchecks/operations-backups-elasticsearch>data>value
    - title: consul-operations
      name: consul
      pkgs:
        - awscli
      settings:
        acl_token: __vault__::secret-operations/{{ ENVIRONMENT }}/consul-acl-master-token>data>value
        duplicity_passphrase: __vault__::secret-operations/global/duplicity-passphrase>data>value
        directory: consul-operations
        healthcheck_url: __vault__::secret-operations/global/healthchecks/operations-backups-consul>data>value
