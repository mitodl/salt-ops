{% set app_name = 'redash' %}
{% set python_version = '2.7.14' %}
{% set python_bin_dir = '/usr/local/pyenv/versions/{0}/bin'.format(python_version) %}
{% set ENVIRONMENT = salt.grains.get('environment', 'operations') %}
{% set env_settings = salt.cp.get_file_str("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml")|load_yaml %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set purpose_data = env_data.purposes[app_name] %}
{% set minion_id = salt.grains.get('id', '') %}
{% set pg_creds = salt.vault.cached_read('postgres-' ~ ENVIRONMENT ~ '-redash/creds/redash', cache_prefix=minion_id) %}
{% set redash_fluentd_webhook_token = salt.vault.read('secret-operations/global/redash_webhook_token').data.value %}
{% set process_count = 4 * salt.grains.get('num_cpus', 2) %}

schedule:
  refresh_{{ app_name }}_credentials:
    days: 5
    function: state.sls
    args:
      - django.config

python:
  versions:
    - number: {{ python_version }}
      default: True
      user: root

redash:
  additional_python_pkgs:
    - pandas
  root_user:
    email: __vault__::secret-{{ purpose_data.business_unit }}/{{ ENVIRONMENT }}/{{ app_name }}/root-user>data>email
    name: __vault__::secret-{{ purpose_data.business_unit }}/{{ ENVIRONMENT }}/{{ app_name }}/root-user>data>name
    password: __vault__::secret-{{ purpose_data.business_unit }}/{{ ENVIRONMENT }}/{{ app_name }}/root-user>data>password

django:
  user: redash
  group: redash
  pip_path: {{ python_bin_dir }}/pip
  app_name: {{ app_name }}
  app_source:
    type: archive # Options are: git, hg, archive
    repository_url: https://s3.amazonaws.com/ol-eng-artifacts/redash/redash-stable.tar.gz
    state_params:
      - overwrite: True
      - source_hash: https://s3.amazonaws.com/ol-eng-artifacts/redash/redash-stable.hash
      - enforce_toplevel: False
  environment:
    # REDASH_GOOGLE_CLIENT_ID: {# google_creds.client_id #}
    # REDASH_GOOGLE_CLIENT_SECRET: {# google_creds.client_secret #}
    REDASH_ADDITIONAL_QUERY_RUNNERS: redash.query_runner.google_analytics,redash.query_runner.python,redash.query_runner.dremio_odbc
    REDASH_COOKIE_SECRET: __vault__:gen_if_missing:secret-operations/operations/redash/cookie-secret>data>value
    REDASH_SECRET_KEY: __vault__:gen_if_missing:secret-operations/operations/redash/secret-key>data>value
    REDASH_DATABASE_URL: postgresql://{{ pg_creds.data.username }}:{{ pg_creds.data.password }}@postgres-redash.service.consul:5432/redash
    REDASH_DATE_FORMAT: YYYY-MM-DD
    REDASH_ENFORCE_HTTPS: 'true'
    REDASH_EVENT_REPORTING_WEBHOOKS: https://log-input.odl.mit.edu/redash-webhook/redash/events?token={{ redash_fluentd_webhook_token }}
    REDASH_HOST: https://bi.odl.mit.edu
    REDASH_LOG_LEVEL: INFO
    REDASH_LOG_PREFIX: REDASH
    REDASH_LOG_STDOUT: 'true'
    REDASH_MAIL_PASSWORD: __vault__::secret-{{ purpose_data.business_unit }}/{{ ENVIRONMENT }}/{{ app_name }}/sendgrid-credentials>data>password
    REDASH_MAIL_PORT: __vault__::secret-{{ purpose_data.business_unit }}/{{ ENVIRONMENT }}/{{ app_name }}/sendgrid-credentials>data>port
    REDASH_MAIL_SERVER: __vault__::secret-{{ purpose_data.business_unit }}/{{ ENVIRONMENT }}/{{ app_name }}/sendgrid-credentials>data>server
    REDASH_MAIL_USERNAME: __vault__::secret-{{ purpose_data.business_unit }}/{{ ENVIRONMENT }}/{{ app_name }}/sendgrid-credentials>data>username
    REDASH_MAIL_USE_TLS: 'true'
    REDASH_MAIL_DEFAULT_SENDER: "'Open Learning BI <odl-devops@mit.edu>'"
    REDASH_MULTI_ORG: 'false'
    REDASH_NAME: MIT Open Learning Business Intelligence
    REDASH_PASSWORD_LOGIN_ENABLED: 'false'
    REDASH_REDIS_URL: redis://redash-redis.service.consul:6379/0
    REDASH_REMOTE_USER_HEADER: MAIL
    REDASH_REMOTE_USER_LOGIN_ENABLED: 'true'
    REDASH_SENTRY_DSN: __vault__::secret-operations/operations/redash/sentry-dsn>data>value
    REDASH_STATIC_ASSETS_PATH: /opt/{{ app_name }}/client/dist/
    REDASH_FLASK_TEMPLATE_PATH: /opt/{{ app_name }}/redash/templates/
  pkgs:
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
      - apps.redash.install_dremio_datasource
    deploy:
      - apps.redash.deploy
      - apps.redash.post_deploy
    config:
      - apps.redash.deploy
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
        - strict: 'true'
        - enable-threads: 'true'
        - vacuum: 'true'
        - single-interpreter: 'true'
        - die-on-term: 'true'
        - need-app: 'true'
        - disable-logging: 'true'
        - log-4xx: 'true'
        - log-5xx: 'true'
        - max-requests: '1000'
        - max-worker-lifetime: '3600'
        - reload-on-rss: '200'
        - worker-reload-mercy: '60'
        - harakiri: '60'
        - py-call-osafterfork: 'true'
        - buffer-size: '65535'
        - post-buffering: '65535'
        - auto-procname: 'true'
        - socket: /var/run/uwsgi/{{ app_name }}.sock
        - chown-socket: 'www-data:redash'
        - chdir: /opt/{{ app_name }}
        - pyhome: /usr/local/pyenv/versions/{{ python_version }}/
        - uid: redash
        - gid: redash
        - processes: 2
        - threads: 50
        - thunder-lock: 'true'
        - logto: /var/log/uwsgi/apps/%n.log
        - module: redash.wsgi:app
        - pidfile: /var/run/uwsgi/{{ app_name }}.pid
        - touch-reload: /opt/{{ app_name }}/deploy_complete.txt
        - for-readline: /opt/{{ app_name }}/.env
        - env: '%(_)'
        - endfor: ''
        - attach-daemon2: >-
            cmd=/usr/local/pyenv/versions/{{ python_version }}/bin/celery worker -A redash.worker -B -c{{ process_count }} -Qscheduled_queries\,queries\,celery --pidfile /opt/{{ app_name }}/celery.pid -Ofair --maxtasksperchild=50 -linfo,
            pidfile=/opt/{{ app_name }}/celery.pid,
            daemonize=true,
            touch=/opt/{{ app_name}}/deploy_complete.txt
