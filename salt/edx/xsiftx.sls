{% set repo = salt.pillar.get('edx:xsiftx:repo',
                              'https://github.com/mitodl/xsiftx') -%}
{% set version = salt.pillar.get('edx:xsiftx:version',
                              'aaa70e170e38e54c5d27a7a926dfd49fd8155fd6') -%}
{% set extra_sifter_repo = salt.pillar.get('edx:xsiftx:extra_sifter_repo',
                              'https://github.com/mitodl/sifters') -%}
{% set extra_sifter_dir = salt.pillar.get('edx:xsiftx:extra_sifter_dir',
                              '/usr/local/share/xsiftx/sifters') -%}
{% set cron_jobs = salt.pillar.get('edx:xsiftx:cron_jobs', []) -%}
{% set run_web = salt.pillar.get('edx:xsiftx:run_web', false) -%}
{% set log_dir = salt.pillar.get('edx:xsiftx:log_dir', '/edx/var/log/xsiftx') -%}


install_xsiftx:
  pip.installed:
    - name: git+https://{{ repo }}@{{ version }}#egg=xsiftx
    - exists_action: w

{% if extra_sifter_repo is not None %}
install_extra_sifters
  git.latest:
    - name: {{ extra_sifter_repo }}
    - target: {{ extra_sifter_dir }}
{% endif %}

{% if run_web %}
install_uwsgi:
  pip.installed:
    - name: uwsgi

create_log_dir:
  file.directory:
    - name: {{ log_dir }}
    - owner: www-data
    - group: www-data

create_xsiftx_config:
  file.managed:
    - name: /etc/init/xsiftx.conf
    - source: salt://edx/templates/xsiftx.yml.j2
    - template: jinja
    - owner: www-data
    - group: www-data
    - mode: 600
    - context:
        edxapp_venv:
        edxapp_app:
        SITE_KEY:
        LOG_LEVEL:
        CELERY_BROKER_URL:
        CELERY_RESULT_BACKEND:
        XSIFTX_CONSUMERS:

create_xsiftx_upstart_script:
  file.managed:
    - name: /etc/init/xsiftx.conf
    - source: salt://edx/templates/xsiftx.conf.j2
    - template: jinja
    - mode: 644
    - context:
        PORT:
        LOG_LEVEL:
        hostname:
        WORKERS:
        WORKER_LOG_FILE:
        LOG_FILE:

start_xsiftx_service:
  service.running:
    - name: xsiftx
    - enable: True
    - require:
      - file: create_xsiftx_config
      - file: create_xsiftx_upstart_config
      - file: create_log_dir
      - pip: install_uwsgi
{% endif %}
