# -*- mode: yaml -*-
{% set environment = salt.grains.get('environment') %}

dagster:
  home: /opt/ol_data_pipelines
  dagit:
    path: /opt/ol_data_pipelines/bin
    flags: -w etc/workspace.yaml
  config:
    instance:
      scheduler:
        module: dagster_cron.cron_scheduler
        class: SystemCronScheduler
      compute_logs:
        module: dagster_aws.s3.compute_log_manager
        class: S3ComputeLogManager
        config:
          bucket: dagster-{{ environment }}/compute-logs/
      run_storage:
        module: dagster_postgres.run_storage
        class: PostgresRunStorage
        config:
          postgres_db:
            username: __vault__:cache:postgres-{{ environment }}/creds/app
            password: __vault__:cache:postgres-{{ environment }}/creds/app
            hostname: dagster_db.service.{{ environment }}.consul
            db_name: dagster
            port: 5432
      event_log_storage:
        module: dagster_postgres.event_log
        class: PostgresEventLogStorage
        config:
          postgres_db:
            username: __vault__:cache:postgres-{{ environment }}/creds/app
            password: __vault__:cache:postgres-{{ environment }}/creds/app
            hostname: dagster_db.service.{{ environment }}.consul
            db_name: dagster
            port: 5432
      schedule_storage:
        module: dagster_postgres.schedule_storage
        class: PostgresScheduleStorage
        config:
          postgres_db:
            username: __vault__:cache:postgres-{{ environment }}/creds/app
            password: __vault__:cache:postgres-{{ environment }}/creds/app
            hostname: dagster_db.service.{{ environment }}.consul
            db_name: dagster
            port: 5432
  pkg_sources:
    - ol-data-pipelines: https://ol-eng-artifacts.s3.amazonaws.com/ol-data-pipelines/ol-data-pipelines_0.1.0_amd64.deb
