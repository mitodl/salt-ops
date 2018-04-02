{% set app_name = 'redash' %}
{% set python_version = '2.7.14' %}
{% set python_bin_dir = '/usr/local/pyenv/versions/{0}/bin'.format(python_version) %}
{% set ENVIRONMENT = salt.grains.get('environment', 'operations') %}
{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set purpose_data = env_data.purposes[app_name] %}
{% set mail_creds = salt.vault.read('secret-' ~ purpose_data.business_unit ~ '/' ~ ENVIRONMENT ~ '/' ~ app_name ~ '/sendgrid-credentials') %}
{% set pg_creds = salt.vault.read('postgres-' ~ ENVIRONMENT ~ '-redash/creds/redash') %}

python:
  versions:
    - number: {{ python_version }}
      default: True
      user: root

django:
  user: redash
  group: redash
  pip_path: {{ python_bin_dir }}/pip
  app_name: {{ app_name }}
  app_source:
    type: archive # Options are: git, hg, archive
    repository_url: https://s3.amazonaws.com/redash-releases/redash.4.0.0-rc.1.b3791.tar.gz
    state_params:
      - overwrite: True
      - source_hash: d5b22cac0c37929a6da243692be5830c4840d19727f01ed43e3d2f803aa642f6
      - enforce_toplevel: False
  environment:
    REDASH_ADDITIONAL_QUERY_RUNNERS: redash.query_runner.google_analytics
    REDASH_COOKIE_SECRET: {{ salt.vault.read('secret-operations/operations/redash/cookie-secret').data.value }}
    REDASH_DATABASE_URL: postgresql://{{ pg_creds.data.username }}:{{ pg_creds.data.password }}@postgres-operations-redash.service.consul:5432/redash
    REDASH_DATE_FORMAT: YYYY-MM-DD
    REDASH_ENFORCE_HTTPS: true
    # REDASH_GOOGLE_CLIENT_ID: {# google_creds.client_id #}
    # REDASH_GOOGLE_CLIENT_SECRET: {# google_creds.client_secret #}
    REDASH_HOST: https://bi.odl.mit.edu
    REDASH_LOG_LEVEL: INFO
    REDASH_MAIL_PASSWORD: {{ mail_creds.data.password }}
    REDASH_MAIL_PORT: {{ mail_creds.data.port }}
    REDASH_MAIL_SERVER: {{ mail_creds.data.server }}
    REDASH_MAIL_USERNAME: {{ mail_creds.data.username }}
    REDASH_MAIL_USE_TLS: true
    REDASH_MULTI_ORG: false
    REDASH_NAME: MIT Open Learning Business Intelligence
    REDASH_PASSWORD_LOGIN_ENABLED: false
    REDASH_REDIS_URL: redis://redis-redash.service.consul:6379/0
    REDASH_SENTRY_DSN: {{ salt.vault.read('secret-operations/operations/redash/sentry-dsn').data.value }}
  pgks:
    - libffi-dev
    - libssl-dev
    - libmariadbclient-dev
    - libpq-dev
    - freetds-dev
    - libsasl2-dev
    - xmlsec1
  states:
    setup:
      - apps.redash.install
    deploy:
      - apps.redash.deploy
    config:
      - apps.redash.datasources

uwsgi:
  overrides:
    pip_path: {{ python_bin_dir }}/pip
    uwsgi_path: {{ python_bin_dir }}/uwsgi
  emperor_config:
    uwsgi:
      - logto: /var/log/uwsgi/emperor.log
  apps:
    {{ app_name }}:
      uwsgi:
        - socket: /var/run/uwsgi/{{ app_name }}.sock
        - chown-socket: 'www-data:redash'
        - chdir: /opt/{{ app_name }}
        - pyhome: /usr/local/pyenv/versions/{{ python_version }}/
        - uid: redash
        - gid: redash
        - processes: 2
        - threads: 50
        - enable-threads: 'true'
        - thunder-lock: 'true'
        - logto: /var/log/uwsgi/apps/%n.log
        - module: redash.wsgi
        - pidfile: /var/run/uwsgi/{{ app_name }}.pid
        - touch-reload: /opt/{{ app_name }}/deploy_complete.txt
        - attach-daemon2: >-
            cmd=/usr/local/pyenv/versions/{{ python_version }}/bin/celery worker -A redash.worker -B -c2 -Qqueries,celery --pidfile /opt/{{ app_name }}/celery.pid -Ofair,
            pidfile=/opt/{{ app_name }}/celery.pid,
            daemonize=true,
            touch=/opt/{{ app_name}}/deploy_complete.txt
        - attach-daemon2: >-
            cmd=/usr/local/pyenv/versions/{{ python_version }}/bin/celery worker -A redash.worker -c2 -Qscheduled_queries --pidfile /opt/{{ app_name }}/celery.pid -Ofair,
            pidfile=/opt/{{ app_name }}/celery.pid,
            daemonize=true,
            touch=/opt/{{ app_name}}/deploy_complete.txt
