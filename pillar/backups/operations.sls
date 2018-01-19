#!jinja|yaml|gpg

{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set duplicity_passphrase = salt.vault.read('secret-operations/global/duplicity-passphrase').data.value %}

backups:
  enabled:
    - title: elasticsearch-operations
      name: elasticsearch
      pkgs:
        - curl
      settings:
        snapshot_repository_name: operations_es_backup
    - title: consul-operations
      name: consul
      pkgs:
        - awscli
      settings:
        acl_token: {{ salt.vault.read('secret-operations/{}/consul-acl-master-token'.format(ENVIRONMENT)).data.value }}
        duplicity_passphrase: {{ duplicity_passphrase }}
        directory: consul-operations
