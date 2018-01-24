# -*- mode: yaml -*-
{% set app_name = 'odlvideo' %}
{% set python_bin_dir = '/usr/local/pyenv/versions/3.6.3/bin' %}

python:
  versions:
    - number: 3.6.3
      default: True
      user: root

django:
  pip_path: {{ python_bin_dir }}/pip3
  django_admin_path: {{ python_bin_dir }}/django-admin
  app_name: {{ app_name }}
  settings_module: odl_video.settings
  automatic_migrations: True
  app_source:
    type: git # Options are: git, hg, archive
    revision: release
    repository_url: https://github.com/mitodl/odl-video-service
    state_params:
      - branch: release
      - force_fetch: True
      - force_checkout: True
      - force_reset: True
  pkgs:
    - build-essential
    - libssl-dev
    - libjpeg-dev
    - zlib1g-dev
    - libpqxx-dev
    - libxml2-dev

uwsgi:
  overrides:
    pip_path: {{ python_bin_dir }}/pip3
    uwsgi_path: {{ python_bin_dir }}/uwsgi
  emperor_config:
    uwsgi:
      logto: /var/log/uwsgi/emperor.log
  apps:
    {{ app_name }}:
      uwsgi:
        socket: /var/run/uwsgi/{{ app_name }}.sock
        chown-socket: www-data:deploy
        chdir: /opt/{{ app_name }}
        home: /usr/local/pyenv/versions/3.6.3/
        uid: deploy
        gid: deploy
        processes: 1
        threads: 10
        enable-threads: 'true'
        thunder-lock: 'true'
        logto: /var/log/uwsgi/apps/%n.log
        module: hc.wsgi
        pidfile: /var/run/uwsgi/{{ app_name }}.pid
        for-readline: /opt/{{ app_name }}/.env
        env: %(_)
        endfor: ''
