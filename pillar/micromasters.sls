micromasters:
  db:
    master_user: __vault__::secret-micromasters/production/rds-credentials>data>username
    master_password: __vault__::secret-micromasters/production/rds-credentials>data>password
    port: 15432
    app_db: micromasters
    app_user: __vault__::secret-micromasters/production/database-credentials>data>username
    app_password: __vault__::secret-micromasters/production/database-credentials>data>password
