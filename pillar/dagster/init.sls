# -*- mode: yaml -*-
{% set environment = salt.grains.get('environment', 'data-qa') %}

dagster:
  home: /opt/ol_data_pipelines
  dagit:
    path: /opt/ol_data_pipelines/bin
    flags:
      - '-w /etc/dagster/workspace.yaml'
  instance_config:
    scheduler:
      module: dagster_cron.cron_scheduler
      class: SystemCronScheduler
    compute_logs:
      module: dagster_aws.s3.compute_log_manager
      class: S3ComputeLogManager
      config:
        bucket: dagster-{{ environment }}
        prefix: compute-logs/
    run_storage:
      module: dagster_postgres.run_storage
      class: PostgresRunStorage
      config:
        postgres_db:
          username: __vault__:cache:postgres-dagster-{{ environment }}/creds/app>data>username
          password: __vault__:cache:postgres-dagster-{{ environment }}/creds/app>data>password
          hostname: dagster_db.service.consul
          db_name: dagster
          port: 5432
    event_log_storage:
      module: dagster_postgres.event_log
      class: PostgresEventLogStorage
      config:
        postgres_db:
          username: __vault__:cache:postgres-dagster-{{ environment }}/creds/app>data>username
          password: __vault__:cache:postgres-dagster-{{ environment }}/creds/app>data>password
          hostname: dagster_db.service.consul
          db_name: dagster
          port: 5432
    schedule_storage:
      module: dagster_postgres.schedule_storage
      class: PostgresScheduleStorage
      config:
        postgres_db:
          username: __vault__:cache:postgres-dagster-{{ environment }}/creds/app>data>username
          password: __vault__:cache:postgres-dagster-{{ environment }}/creds/app>data>password
          hostname: dagster_db.service.consul
          db_name: dagster
          port: 5432
  pipeline_configs:
  pkg_sources:
    - ol-data-pipelines: https://ol-eng-artifacts.s3.amazonaws.com/ol-data-pipelines/ol-data-pipelines_0.1.9_amd64.deb
