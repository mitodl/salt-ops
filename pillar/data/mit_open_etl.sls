{% set minion_id = salt.grains.get('id', '') %}
{% set db_creds = salt.vault.cached_read('postgresql-production-apps-opendiscussions/creds/readonly', cache_prefix=minion_id) %}

etl_dependencies:
  - python3
  - python3-pip
  - python3-virtualenv
  - git
  - awscli
  - libpqxx-dev

etl_config:
  task_name: mit-open
  mit-open:
    db_url: postgresql://{{ db_creds.data.username }}:{{ db_creds.data.password }}@postgres-opendiscussions.service.production-apps.consul:5432/opendiscussions
    s3_bucket: mitodl-data-lake/mailgun
    hash_salt: __vault__::secret-operations/global/anonymizer-hash-salt>data>value
    aws_access_key_id: __vault__:cache:aws-mitx/creds/read-write-mitodl-data-lake>data>access_key
    aws_secret_access_key: __vault__:cache:aws-mitx/creds/read-write-mitodl-data-lake>data>secret_key
