{% set minion_id = salt.grains.get('id', '') %}
{% set xpro_db_creds = salt.vault.cached_read('postgres-production-apps-mitxpro/creds/readonly', cache_prefix=minion_id) %}
{% set open_db_creds = salt.vault.cached_read('postgresql-production-apps-opendiscussions/creds/readonly', cache_prefix=minion_id) %}

etl_dependencies:
  - python3
  - python3-pip
  - virtualenv
  - git
  - awscli
  - libpqxx-dev

etl:
  task_name: email_mapping
  configs:
    - mitxpro:
        db_url: postgresql://{{ xpro_db_creds.data.username }}:{{ xpro_db_creds.data.password }}@postgresql-mitxpro.service.production-apps.consul:5432/mitxpro
        s3_bucket: mitodl-data-lake/mailgun
        hash_salt: __vault__::secret-operations/global/anonymizer-hash-salt>data>value
        aws_access_key_id: __vault__:cache:aws-mitx/creds/read-write-mitodl-data-lake>data>access_key
        aws_secret_access_key: __vault__:cache:aws-mitx/creds/read-write-mitodl-data-lake>data>secret_key
    - mit_open:
        db_url: postgresql://{{ open_db_creds.data.username }}:{{ open_db_creds.data.password }}@postgresql-opendiscussions.service.production-apps.consul:5432/opendiscussions
        s3_bucket: mitodl-data-lake/mailgun
        hash_salt: __vault__::secret-operations/global/anonymizer-hash-salt>data>value
        aws_access_key_id: __vault__:cache:aws-mitx/creds/read-write-mitodl-data-lake>data>access_key
        aws_secret_access_key: __vault__:cache:aws-mitx/creds/read-write-mitodl-data-lake>data>secret_key
