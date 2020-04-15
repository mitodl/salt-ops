alcali:
  deploy:
    repository: https://github.com/mitodl/alcali-formula/alcali.git
    branch: 2019.2
    user: alcali
    group: alcali
    directory: /opt/alcali
    service: alcali
    runtime: python3
  gunicorn:
    name: 'config.wsgi:application'
    host: '0.0.0.0'
    port: 8000
    workers: {{ grains['num_cpus'] }}
  config:
    db_backend: postgresql
    db_name: saltmaster
    db_user: __vault__:cache:postgres-operations-saltmaster/creds/saltmaster>data>username
    db_password: __vault__:cache:postgres-operations-saltmaster/creds/saltmaster>data>password
    db_host: operations-rds-postgres-saltmaster.cbnm7ajau6mi.us-east-1.rds.amazonaws.com
    db_port: 5432
    master_minion_id: master-operations-production
    secret_key: __vault__:gen_if_missing:secret-operations/production/alcali-secret-key>data>value
    allowed_hosts: '*'
    salt_url: 'https://salt-production.private.odl.mit.edu:8080'
    salt_auth: rest
