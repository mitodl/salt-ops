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
{% set edxapp_venv = salt.pillar.get('edx:xsiftx:edxapp_venv', '/edx/app/edxapp/venvs/edxapp') -%}
{% set edxapp_app = salt.pillar.get('edx:xsiftx:edxapp_app', '/edx/app/edxapp/edx-platform') -%}
{% set web = salt.pillar.get('edx:xsiftx:web', {
  "PORT": "8094",
  "LOG_FILE": "{{ xsiftx_log_dir }}/xsiftx_uwsgi.log",
  "WORKER_LOG_FILE": "{{ xsiftx_log_dir }}/xsiftx_celery.log",
  "LOG_LEVEL": "INFO",
  "CELERY_BROKER_URL": "amqp://celery:celery@localhost:5672//",
  "CELERY_RESULT_BACKEND": "amqp",
  "SITE_KEY": "please_change_this_within_your_own_or_bad_things",
  "WORKERS": 1,
  "CONSUMERS": {
    "consumers": []
  }
}) -%}


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

{% for item in cron_jobs %}
xsiftx_{{ item.name }}_cron:
  cron.present:
    - comment: {{ item.name }}
    - hour: {{ item.cron_hour }}
    - minute: {{ item.cron_minute }}
    - weekday: {{ item.cron_weekday|default('*')}}
    - user: www-data
    - name: "export PATH=$PATH:/usr/local/bin; xsiftx -v {{ edxapp_venv }} -e {{ edxapp_app }} {{ item.sifter }}"
    - require:
      - pip: install_xsiftx
{% endfor %}

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
        web: {{ web }}
        edxapp_venv: {{ edxapp_venv }}
        edxapp_app: {{ edxapp_app }}

create_xsiftx_upstart_script:
  file.managed:
    - name: /etc/init/xsiftx.conf
    - source: salt://edx/templates/xsiftx.conf.j2
    - template: jinja
    - mode: 644
    - context:
        web: {{ web }}
        hostname:

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
