# -*- mode: yaml -*-
{% set app_name = 'mitx-cas' %}
{% set python_version = '2.7.15' %}
{% set python_bin_dir = '/usr/local/pyenv/versions/{0}/bin'.format(python_version) %}
{% set ENVIRONMENT = salt.grains.get('environment', 'mitx-qa') %}
{% set minion_id = salt.grains.get('id', '') %}
{% set env_dict = {
    'mitx-qa': {
      'domain': 'auth.mitx.mit.edu',
      'log_level': 'DEBUG',
      'release_branch': 'master'
      },
    'mitx-production': {
      'domain': 'cas.mitx.mit.edu',
      'log_level': 'WARN',
      'release_branch': 'master'
      }
} %}
{% set env_data = env_dict[ENVIRONMENT] %}


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

django:
  pip_path: {{ python_bin_dir }}/pip2
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
        - touch-reload: /etc/mitx-cas/config.yml
        - max-requests: 1000
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
        HOST: postgres-mitxcas.service.consul
    SECRET_KEY: __vault__:gen_if_missing:secret-residential/{{ ENVIRONMENT }}/mitx-cas/django-secret-key>data>value
    CAS_ALLOWED_SERVICES:
      - host: ^lore-ci.herokuapp.com$
        provider: touchstone
      - host: ^lore-demo.herokuapp.com$
        provider: touchstone
      - host: ^lore-rc.herokuapp.com$
        provider: touchstone
      - host: ^lore-release.herokuapp.com$
        provider: touchstone
      - host: ^lore.odl.mit.edu$
        provider: touchstone
      - host: ^www.lore.odl.mit.edu$
        provider: touchstone
      - host: ^introml.odl.mit.edu
        provider: touchstone
      - host: ^ga.odl.mit.edu
        provider: touchstone
    STATIC_ROOT: /opt/mitx-cas/static
    ZENDESK_PSK: __vault__::secret-operations/global/zendesk-cas-psk>data>value
