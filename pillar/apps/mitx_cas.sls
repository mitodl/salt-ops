# -*- mode: yaml -*-
{% set app_name = 'mitx-cas' %}
{% set ENVIRONMENT = salt.grains.get('environment', 'mitx-qa') %}
{% set minion_id = salt.grains.get('id', '') %}
{% set env_dict = {
    'mitx-qa': {
      'domain': 'auth.mitx.mit.edu',
      'log_level': 'DEBUG',
      'release_branch': 'master',
      'python_version': '3.8.6'
      },
    'mitx-production': {
      'domain': 'cas.mitx.mit.edu',
      'log_level': 'WARN',
      'release_branch': 'master',
      'python_version': '3.8.6'
      }
} %}
{% set env_data = env_dict[ENVIRONMENT] %}
{% set python_bin_dir = '/usr/local/pyenv/versions/{0}/bin'.format(env_data.python_version) %}
{% set rds_endpoint = salt.boto_rds.get_endpoint(ENVIRONMENT ~ '-rds-postgres-mitxcas') %}

schedule:
  refresh_{{ app_name }}_credentials:
    days: 5
    function: state.sls
    args:
      - django.config

python:
  versions:
    - number: {{ env_data.python_version }}
      default: True
      user: root

django:
  pip_path: {{ python_bin_dir }}/pip
  django_admin_path: {{ python_bin_dir }}/django-admin
  app_name: {{ app_name }}
  settings_module: mitx_cas.settings
  automatic_migrations: True
  environment:
    CONFIG_ROOT: /etc/mitx-cas/
  app_source:
    type: git # Options are: git, hg, archive
    revision: {{ env_data.release_branch }}
    repository_url: git@github.mit.edu:mitx-devops/mitx-cas
    state_params:
      - branch: {{ env_data.release_branch }}
      - force_fetch: True
      - force_checkout: True
      - force_reset: True
      - identity: /opt/keys/mitx_cas_deploy_key
      - user: deploy

  pkgs:
    - git
    - build-essential
    - libssl-dev
    - libjpeg-dev
    - zlib1g-dev
    - libpqxx-dev
    - libxml2-dev
    - libxslt2-dev
    - libffi-dev
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
        - buffer-size: '65535'
        - post-buffering: '65535'
        - auto-procname: 'true'
        - chdir: /opt/{{ app_name }}
        - chown-socket: 'www-data:deploy'
        - disable-write-exception: 'true'
        - gid: deploy
        - logto: /var/log/uwsgi/apps/%n.log
        - memory-report: 'true'
        - module: mitx_cas.wsgi
        - pidfile: /var/run/uwsgi/{{ app_name }}.pid
        - processes: 2
        - pyhome: /usr/local/pyenv/versions/{{ env_data.python_version }}/
        - socket: /var/run/uwsgi/{{ app_name }}.sock
        - threads: 50
        - thunder-lock: 'true'
        - touch-reload: /etc/mitx-cas/cas.yml
        - uid: deploy
        - env: CONFIG_ROOT=/etc/mitx-cas/

mitx_cas:
  deploy_key: __vault__::secret-residential/global/mitx-cas/github-deploy-key>data>value
  config:
    DATABASES:
      default:
        ENGINE: "django.db.backends.postgresql_psycopg2"
        NAME: mitxcas
        USER: __vault__:cache:postgres-{{ ENVIRONMENT }}-mitxcas/creds/mitxcas>data>username
        PASSWORD: __vault__:cache:postgres-{{ ENVIRONMENT }}-mitxcas/creds/mitxcas>data>password
        HOST: {{ rds_endpoint.split(':')[0] }}
    SECRET_KEY: __vault__:gen_if_missing:secret-residential/{{ ENVIRONMENT }}/mitx-cas/django-secret-key>data>value
    CAS_ALLOWED_SERVICES:
      - host: ^introml.odl.mit.edu
        provider: touchstone
      - host: ^ga.odl.mit.edu
        provider: touchstone
      - host: ^qisx.odl.mit.edu
        provider: touchstone
      - host: ^eecs.odl.mit.edu
        provider: touchstone
      - host: ^go.odl.mit.edu
        provider: touchstone
      - host: ^vote.odl.mit.edu
        provider: touchstone
      - host: ^commencement.odl.mit.edu
        provider: touchstone
      - host: ^canvas.odl.mit.edu
        provider: touchstone
      - host: ^greetings.odl.mit.edu
        provider: touchstone
      - host: ^quanta.mit.edu
        provider: touchstone
      - host: ^futonhub.mit.edu
        provider: touchstone
    STATIC_ROOT: /opt/mitx-cas/static
    ZENDESK_PSK: __vault__::secret-operations/global/zendesk-cas-psk>data>value
