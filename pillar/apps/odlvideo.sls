# -*- mode: yaml -*-
{% set app_name = 'odl-video-service' %}
{% set python_version = '3.6.8' %}
{% set python_bin_dir = '/usr/local/pyenv/versions/{0}/bin'.format(python_version) %}
{% set ENVIRONMENT = salt.grains.get('environment', 'dev') %}
{% set env_dict = {
    'ci': {
      'env_name': 'ci',
      'bucket_suffix': 'ci',
      'domain': 'video-ci.odl.mit.edu',
      'log_level': 'DEBUG',
      'use_shibboleth': False,
      'ga_id': 'UA-5145472-26',
      'ga_view_id': '163329706',
      'transcode_pipeline_id': '1506027488410-93oya5',
      'youtube_project_id': 'ovs-youtube-qa',
      'release_branch': 'master',
      'cloudfront_subdomain': 'd2jnipcnro4zno',
      'redis_max_connections': 30,
      'EDX_BASE_URL': 'https://courses-ci.xpro.mit.edu'
      },
    'rc-apps': {
      'env_name': 'rc',
      'bucket_suffix': 'rc',
      'domain': 'video-rc.odl.mit.edu',
      'log_level': 'INFO',
      'use_shibboleth': True,
      'ga_id': 'UA-5145472-26',
      'ga_view_id': '163329706',
      'transcode_pipeline_id': '1506081628031-bepkel',
      'youtube_project_id': 'ovs-youtube-qa',
      'release_branch': 'release-candidate',
      'cloudfront_subdomain': 'du3yhovcx8dht',
      'redis_max_connections': 65000,
      'EDX_BASE_URL': 'https://courses-rc.xpro.mit.edu'
      },
    'production-apps': {
      'env_name': 'production',
      'bucket_suffix': '',
      'domain': 'video.odl.mit.edu',
      'log_level': 'WARN',
      'use_shibboleth': True,
      'ga_id': 'UA-5145472-27',
      'ga_view_id': '163330947',
      'transcode_pipeline_id': '1497541042228-8mpenl',
      'youtube_project_id': 'ovs-youtube-production',
      'release_branch': 'release',
      'cloudfront_subdomain': 'd3tsb3m56iwvoq',
      'redis_max_connections': 65000,
      'EDX_BASE_URL': 'https://courses.xpro.mit.edu'
      }
} %}
{% set env_data = env_dict[ENVIRONMENT] %}
{% set minion_id = salt.grains.get('id', '') %}
{% set pg_creds = salt.vault.cached_read('postgres-{env}-odlvideo/creds/odlvideo'.format(env=ENVIRONMENT), cache_prefix=minion_id) %}
{% set rabbit_creds = salt.vault.cached_read("rabbitmq-{env}/creds/odlvideo".format(env=ENVIRONMENT), cache_prefix=minion_id) %}
{% set ga_json = salt.vault.read('secret-odl-video/' ~ ENVIRONMENT ~ '/ga-keyfile-json').data.value|json %}
{% set business_unit = 'odl-video' %}

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
    {% if env_data.env_name == 'rc' %}
    FEATURE_VIDEOJS_ANNOTATIONS: True
    {% endif %}
    AWS_ACCESS_KEY_ID: __vault__:cache:aws-mitx/creds/odl-video-service-{{ env_data.env_name }}>data>access_key
    AWS_REGION: us-east-1
    AWS_S3_DOMAIN: s3.amazonaws.com
    AWS_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/odl-video-service-{{ env_data.env_name }}>data>secret_key
    CLOUDFRONT_KEY_ID: __vault__::secret-operations/global/cloudfront-private-key>data>id
    CLOUDFRONT_PRIVATE_KEY: __vault__::secret-operations/global/cloudfront-private-key>data>value
    CELERY_BROKER_URL: amqp://{{ rabbit_creds.data.username }}:{{ rabbit_creds.data.password }}@nearest-rabbitmq.query.consul//odlvideo
    DATABASE_URL: postgres://{{ pg_creds.data.username }}:{{ pg_creds.data.password }}@postgres-odlvideo.service.consul:5432/odlvideo
    DJANGO_LOG_LEVEL: {{ env_data.log_level }}
    DROPBOX_FOLDER: /Captions
    DROPBOX_KEY: __vault__::secret-{{ business_unit }}/{{ ENVIRONMENT }}/dropbox_app>data>key
    DROPBOX_TOKEN: __vault__::secret-{{ business_unit }}/{{ ENVIRONMENT }}/dropbox_app>data>token
    EDX_BASE_URL: {{ env_data.EDX_BASE_URL }}
    ENABLE_VIDEO_PERMISSIONS: True
    ET_PIPELINE_ID: {{ env_data.transcode_pipeline_id }}
    ET_PRESET_IDS: 1504127981921-c2jlwt,1504127981867-06dkm6,1504127981819-v44xlx,1504127981769-6cnqhq,1351620000001-200040,1351620000001-200050
    FEATURE_RETRANSCODE_ENABLED: True
    GA_DIMENSION_CAMERA: dimension1
    GA_KEYFILE_JSON: '{{ ga_json }}'
    GA_VIEW_ID: {{ env_data.ga_view_id }}
    GA_TRACKING_ID: {{ env_data.ga_id }}
    LECTURE_CAPTURE_USER: {{ salt.sdb.get('sdb://consul/odl-video-service/lecture-capture-user') }}
    MAILGUN_KEY: __vault__::secret-operations/global/mailgun-api-key>data>value
    MAILGUN_URL: https://api.mailgun.net/v3/video-mail.odl.mit.edu
    # Cert and private key need to be stored in vault as strings
    MIT_WS_CERTIFICATE: __vault__::secret-{{ business_unit }}/{{ env_data.env_name }}/mit-application-certificate>data>certificate
    MIT_WS_PRIVATE_KEY: __vault__::secret-{{ business_unit }}/{{ env_data.env_name }}/mit-application-certificate>data>private_key
    ODL_VIDEO_ADMIN_EMAIL: cuddle_bunnies@mit.edu
    ODL_VIDEO_BASE_URL: https://{{ env_data.domain }}
    ODL_VIDEO_ENVIRONMENT: {{ ENVIRONMENT }}
    ODL_VIDEO_FROM_EMAIL: MIT ODL Video <odl-video-support@mit.edu>
    ODL_VIDEO_LOG_LEVEL: {{ env_data.log_level }}
    ODL_VIDEO_SUPPORT_EMAIL: MIT ODL Video <odl-video-support@mit.edu>
    ODL_VIDEO_LOG_FILE: /var/log/odl-video/django.log
    OPENEDX_API_CLIENT_ID: __vault__::secret-{{ business_unit }}/{{ ENVIRONMENT }}/openedx-api>data>client_id
    OPENEDX_API_CLIENT_SECRET: __vault__::secret-{{ business_unit }}/{{ ENVIRONMENT }}/openedx-api>data>client_secret
    REDIS_URL: redis://ovs-{{ env_data.env_name }}-redis.service.consul:6379/0
    REDIS_MAX_CONNECTIONS: {{ env_data.redis_max_connections }}
    SECRET_KEY: __vault__::secret-{{ business_unit }}/{{ ENVIRONMENT }}/django-secret-key>data>value
    SENTRY_DSN: __vault__::secret-{{ business_unit }}/global/sentry-dsn>data>value
    STATUS_TOKEN: {{ ENVIRONMENT }}
    USE_SHIBBOLETH: {{ env_data.use_shibboleth }}
    VIDEO_CLOUDFRONT_DIST: {{ env_data.cloudfront_subdomain }}
    VIDEO_S3_BUCKET: odl-video-service{{ '-{}'.format(env_data.bucket_suffix).rstrip('-') }}
    VIDEO_S3_SUBTITLE_BUCKET: odl-video-service-subtitles{{ '-{}'.format(env_data.bucket_suffix).rstrip('-') }}
    VIDEO_S3_THUMBNAIL_BUCKET: odl-video-service-thumbnails{{ '-{}'.format(env_data.bucket_suffix).rstrip('-') }}
    VIDEO_S3_TRANSCODE_BUCKET: odl-video-service-transcoded{{ '-{}'.format(env_data.bucket_suffix).rstrip('-') }}
    VIDEO_S3_WATCH_BUCKET: odl-video-service-uploaded{{ '-{}'.format(env_data.bucket_suffix).rstrip('-') }}
    VIDEO_STATUS_UPDATE_FREQUENCY: 60
    VIDEO_WATCH_BUCKET_FREQUENCY: 600
    YT_ACCESS_TOKEN: __vault__::secret-{{ business_unit }}/{{ ENVIRONMENT }}/youtube-credentials>data>access_token
    YT_CLIENT_ID: __vault__::secret-{{ business_unit }}/{{ ENVIRONMENT }}/youtube-credentials>data>client_id
    YT_CLIENT_SECRET: __vault__::secret-{{ business_unit }}/{{ ENVIRONMENT }}/youtube-credentials>data>client_secret
    YT_PROJECT_ID: {{ env_data.youtube_project_id }}
    YT_REFRESH_TOKEN: __vault__::secret-{{ business_unit }}/{{ ENVIRONMENT }}/youtube-credentials>data>refresh_token
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
    config:
      - apps.odlvideo.configure
    post_install:
      - apps.odlvideo.post_deploy
      - apps.odlvideo.deploy_signal

uwsgi:
  overrides:
    pip_path: {{ python_bin_dir }}/pip3
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
        - chdir: /opt/{{ app_name }}
        - chown-socket: 'www-data:deploy'
        - disable-write-exception: 'true'
        - gid: deploy
        - logto: /var/log/uwsgi/apps/%n.log
        - memory-report: 'true'
        - module: odl_video.wsgi
        - pidfile: /var/run/uwsgi/{{ app_name }}.pid
        - processes: 2
        - pyhome: /usr/local/pyenv/versions/{{ python_version }}/
        - socket: /var/run/uwsgi/{{ app_name }}.sock
        - threads: 50
        - thunder-lock: 'true'
        - touch-reload: /opt/{{ app_name }}/deploy_complete.txt
        - uid: deploy
        - attach-daemon2: >-
            cmd=/usr/local/pyenv/versions/{{ python_version }}/bin/celery worker -A odl_video -B --pidfile /opt/{{ app_name }}/celery.pid -l {{ env_data.log_level }},
            pidfile=/opt/{{ app_name }}/celery.pid,
            daemonize=true,
            touch=/opt/{{ app_name}}/deploy_complete.txt


node:
  install_from_binary: True
  version: 13.13.0

beacons:
  memusage:
    - percent: 95%
