# -*- mode: yaml -*-
{% set app_name = 'starcellbio' %}
{% set python_version = '2.7.15' %}
{% set python_bin_dir = '/usr/local/pyenv/versions/{0}/bin'.format(python_version) %}
{% set ENVIRONMENT = salt.grains.get('environment', 'rc-apps') %}
{% set minion_id = salt.grains.get('id', '') %}
{% set env_dict = {
    'rc-apps': {
      'log_level': 'DEBUG',
      'release_branch': 'develop'
      },
    'production-apps': {
      'log_level': 'WARN',
      'release_branch': 'release'
      }
} %}
{% set env_data = env_dict[ENVIRONMENT] %}


python:
  versions:
    - number: {{ python_version }}
      default: True
      user: root

django:
  pip_path: {{ python_bin_dir }}/pip2
  django_admin_path: {{ python_bin_dir }}/django-admin
  app_name: {{ app_name }}
  settings_module: StarCellBio.settings
  automatic_migrations: True
  app_source:
    type: git # Options are: git, hg, archive
    revision: {{ env_data.release_branch }}
    repository_url: https://github.com/starteam/starcellbio_html.git
    state_params:
      - branch: {{ env_data.release_branch }}
      - force_fetch: True
      - force_checkout: True
      - force_reset: True
      - identity: /opt/keys/mitx_cas_deploy_key
      - user: deploy

  pkgs:
    - libmariadbclient-dev
    - mariadb-client
    - build-essential
    - libncurses5-dev
    - python-mysqldb
    - openjdk-8-jre
    - nodejs
    - npm
    - libxml2-dev
    - libxslt-dev
    - git
    - libssl-dev
    - libjpeg-dev
    - zlib1g-dev
  states:
    setup:
      - apps.mitx_cas.install
    config:
      - apps.mitx_cas.configure

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
        - buffer-size: 65535
        - chdir: /opt/{{ app_name }}
        - chown-socket: 'www-data:deploy'
        - disable-write-exception: 'true'
        - enable-threads: 'true'
        - gid: deploy
        - logto: /var/log/uwsgi/apps/%n.log
        - memory-report: 'true'
        - module: mitx_cas.wsgi
        - pidfile: /var/run/uwsgi/{{ app_name }}.pid
        - post-buffering: 65535
        - processes: 2
        - pyhome: /usr/local/pyenv/versions/{{ python_version }}/
        - socket: /var/run/uwsgi/{{ app_name }}.sock
        - threads: 50
        - thunder-lock: 'true'
        - max-requests: 1000
        - uid: deploy

starcellbio:
  config:
    SECRET_KEY: __vault__:gen_if_missing:secret-starteam/{{ ENVIRONMENT }}/starcellbio/django-secret-key>data>value
    PROJECT_HOME: /opt/{{ app_name }}
    DEBUG: False
    LOG_LEVEL: {{ env_dict[ENVIRONMENT].log_level }}
    SCB_TIME_ZONE: America/New_York
    DB_ENGINE: django.db.backends.mysql
    DB_NAME: starcellbio
    DB_USER: __vault__:cache:mariadb-{{ ENVIRONMENT }}-starcellbio/creds/starcellbio>data>username
    DB_PASSWORD: __vault__:cache:mariadb-{{ ENVIRONMENT }}-starcellbio/creds/starcellbio>data>password
    DB_HOST: mariadb-starcellbio.service.consul
    DB_PORT: 3306
    TEMPLATE_DEBUG: false
    SERVER_EMAIL: mitxmail@mit.edu
    ADMINS:
      -
        - mitx-devops
        - mitx-devops@mit.edu
    S3_BACKEND_ENABLED: True
    DEFAULT_FILE_STORAGE: storages.backends.s3boto3.S3Boto3Storage
    AWS_ACCESS_KEY_ID: __vault__:cache:aws-mitx/creds/read-write-delete-scb-{{ ENVIRONMENT }}-microscopy-uploads>data>access_key
    AWS_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/read-write-delete-scb-{{ ENVIRONMENT }}-microscopy-uploads>data>secret_key
    AWS_STORAGE_BUCKET_NAME: scb-{{ ENVIRONMENT }}-microscopy-uploads

node:
  install_from_binary: True
  version: 8.11.4
