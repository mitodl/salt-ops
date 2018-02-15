# -*- mode: yaml -*-
{% set app_name = 'odl-video-service' %}
{% set python_version = '3.6.4' %}
{% set python_bin_dir = '/usr/local/pyenv/versions/{0}/bin'.format(python_version) %}
{% set ENVIRONMENT = salt.grains.get('environment', 'dev') %}
{% set aws_creds = salt.vault.read('aws-mitx/creds/odl-video-service-{env}'.format(env=ENVIRONMENT)) %}
{% set pg_creds = salt.vault.read('postgres-{env}-odlvideo/creds/odlvideo'.format(env=ENVIRONMENT)) %}
{% set youtube_creds = salt.vault.read('secret-odl-video/{env}/youtube-credentials'.format(env=ENVIRONMENT)) %}
{% set app_cert = salt.vault.read('secret-odl-video/global/mit-application-certificate') %}
{% set cloudfront_key = salt.vault.read('secret-operations/global/cloudfront-private-key') %}

{% set env_dict = {
    'ci': {
      'domain': 'video-ci.odl.mit.edu',
      'log_level': 'DEBUG',
      'use_shibboleth': False,
      'ga_id': 'UA-108097284-1',
      'transcode_pipeline_id': '1506027488410-93oya5',
      'youtube_project_id': 'ovs-youtube-qa',
      'release_branch': 'master'
      },
    'rc-apps': {
      'domain': 'video-rc.odl.mit.edu',
      'log_level': 'INFO',
      'use_shibboleth': True,
      'ga_id': 'UA-5145472-27',
      'transcode_pipeline_id': '1506081628031-bepkel',
      'youtube_project_id': 'ovs-youtube-qa',
      'release_branch': 'release-candidate'
      },
    'production-apps': {
      'domain': 'video.odl.mit.edu',
      'log_level': 'WARN',
      'use_shibboleth': True,
      'ga_id': 'UA-5145472-27',
      'transcode_pipeline_id': '1497541042228-8mpenl',
      'youtube_project_id': 'ovs-youtube-production',
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
  pip_path: {{ python_bin_dir }}/pip3
  django_admin_path: {{ python_bin_dir }}/django-admin
  app_name: {{ app_name }}
  settings_module: odl_video.settings
  automatic_migrations: True
  app_source:
    type: git # Options are: git, hg, archive
    revision: {{ env_data.release_branch }}
    repository_url: https://github.com/mitodl/odl-video-service
    state_params:
      - branch: {{ env_data.release_branch }}
      - force_fetch: True
      - force_checkout: True
      - force_reset: True
  environment:
    AWS_ACCESS_KEY_ID: {{ aws_creds.data.access_key }}
    AWS_REGION: us-east-1
    AWS_S3_DOMAIN: s3.amazonaws.com
    AWS_SECRET_ACCESS_KEY: {{ aws_creds.data.secret_key }}
    CLOUDFRONT_KEY_ID: {{ cloudfront_key.data.id }}
    CLOUDFRONT_PRIVATE_KEY: {{ cloudfront_key.data.value }}
    DATABASE_URL: postgres://{{ pg_creds.data.username }}:{{ pg_creds.data.password }}@postgres-odlvideo.service.consul:5432/odlvideo
    DJANGO_LOG_LEVEL: {{ env_data.log_level }}
    DROPBOX_KEY: {{ salt.vault.read('secret-odl-video/global/dropbox-key').data.value }}
    ENABLE_VIDEO_PERMISSIONS: False
    ET_PIPELINE_ID: {{ env_data.transcode_pipeline_id }}
    GA_DIMENSION_CAMERA: dimension1
    GA_TRACKING_ID: {{ env_data.ga_id }}
    LECTURE_CAPTURE_USER: {{ salt.sdb.get('sdb://consul/odl-video-service/lecture-capture-user') }}
    MAILGUN_KEY: {{ salt.vault.read('secret-operations/global/mailgun-api-key').data.value }}
    MAILGUN_URL: https://api.mailgun.net/v3/video.odl.mit.edu
    MIT_WS_CERTIFICATE: {{ app_cert.data.certificate }}
    MIT_WS_PRIVATE_KEY: {{ app_cert.data.private_key }}
    ODL_VIDEO_ADMIN_EMAIL: cuddle_bunnies@mit.edu
    ODL_VIDEO_BASE_URL: https://{{ env_data.domain }}
    ODL_VIDEO_ENVIRONMENT: {{ ENVIRONMENT }}
    ODL_VIDEO_FROM_EMAIL: MIT ODL Video <odl-video-support@mit.edu>
    ODL_VIDEO_LOG_LEVEL: {{ env_data.log_level }}
    ODL_VIDEO_SUPPORT_EMAIL: odl-video-support@mit.edu
    REDIS_URL: redis://ovs-rc-redis.service.consul
    SECRET_KEY: {{ salt.vault.read('secret-odl-video/{env}/django-secret-key'.format(env=ENVIRONMENT)).data.value }}
    SENTRY_DSN: {{ salt.vault.read('secret-odl-video/global/sentry-dsn').data.value }}
    STATUS_TOKEN: {{ salt.vault.read('secret-odl-video/{env}/django-status-token'.format(env=ENVIRONMENT)).data.value }}
    USE_SHIBBOLETH: {{ env_data.use_shibboleth }}
    USWITCH_URL: https://s3.amazonaws.com/odl-video-service-uswitch-dev/prod
    VIDEO_CLOUDFRONT_DIST: {{ salt.boto_cloudfront.get_distribution('odl-video-service-{env}'.format(env=ENVIRONMENT.split('-')[0])).result.distribution.Id }}
    VIDEO_S3_BUCKET: odl-video-service-{{ ENVIRONMENT }}
    VIDEO_S3_SUBTITLE_BUCKET: odl-video-service-subtitles-{{ ENVIRONMENT }}
    VIDEO_S3_THUMBNAIL_BUCKET: odl-video-service-thumbnails-{{ ENVIRONMENT }}
    VIDEO_S3_TRANSCODE_BUCKET: odl-video-service-transcoded-{{ ENVIRONMENT }}
    VIDEO_S3_WATCH_BUCKET: odl-video-service-uploaded-{{ ENVIRONMENT }}
    VIDEO_STATUS_UPDATE_FREQUENCY: 60
    VIDEO_WATCH_BUCKET_FREQUENCY: 30
    YT_ACCESS_TOKEN: {{ youtube_creds.data.access_token }}
    YT_CLIENT_ID: {{ youtube_creds.data.client_id }}
    YT_CLIENT_SECRET: {{ youtube_creds.data.client_secret }}
    YT_PROJECT_ID: {{ env_data.youtube_project_id }}
    YT_REFRESH_TOKEN: {{ youtube_creds.data.refresh_token }}
  pkgs:
    - git
    - build-essential
    - libssl-dev
    - libjpeg-dev
    - zlib1g-dev
    - libpqxx-dev
    - libxml2-dev
    - libffi-dev
    - libmariadbclient-dev
  states:
    setup:
      - apps.odlvideo.install
    post_install:
      - apps.odlvideo.post_deploy

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
        chown-socket: 'www-data:deploy'
        chdir: /opt/{{ app_name }}
        pyhome: /usr/local/pyenv/versions/{{ python_version }}/
        uid: deploy
        gid: deploy
        processes: 1
        threads: 10
        enable-threads: 'true'
        thunder-lock: 'true'
        logto: /var/log/uwsgi/apps/%n.log
        module: odl_video.wsgi
        pidfile: /var/run/uwsgi/{{ app_name }}.pid
        for-readline: /opt/{{ app_name }}/.env
        env: '%(_)'
        endfor: ''
        touch-reload: /opt/{{ app_name }}/deploy_complete.txt
        attach-daemon2: >-
          cmd=celery worker -A odl_video --pidfile /var/run/{{ app_name }}/celery.pid,
          pidfile=/var/run/{{ app_name }}/celery.pid,
          daemonize=true,
          touch=/opt/{{ app_name}}/deploy_complete.txt

node:
  install_from_binary: True
  version: 8.5.0
