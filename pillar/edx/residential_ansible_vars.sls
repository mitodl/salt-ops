{% set DEFAULT_FEEDBACK_EMAIL = 'mitx-support@mit.edu' %}
{% set DEFAULT_FROM_EMAIL = 'mitx-support@mit.edu' %}
{% set business_unit = salt.grains.get('business_unit', 'residential') %}
{% set remote_gradebook = salt.vault.read(
    'secret-{business_unit}/{env}/remote_gradebook'.format(
        business_unit=business_unit, env=environment)) %}
{% set EDXAPP_LMS_ISSUER = "https://{}/oauth2".format(LMS_DOMAIN) %}
{% set EDXAPP_CMS_ISSUER = "https://{}/oauth2".format(CMS_DOMAIN) %}

edx:
  ansible_vars:
    XQUEUE_WORKERS_PER_QUEUE: 2
    XQUEUE_QUEUES:
        'MITx-42.01x': 'https://xserver.mitx.mit.edu/fgxserver'
        'MITx-8371': 'https://xqueue.mitx.mit.edu/qis_xserver'
        # TODO: Are these courses still in use? Can we shut down the xserver instance? (tmacey 2017-03-16)
        'MITx-6.s064x': 'http://127.0.0.1:8051'
        'MITx-7.QBWr': 'http://127.0.0.1:8050'
        'matlab': 'https://mitx.mss-mathworks.com/stateless/mooc/MITx'
        # push queue
        'edX-DemoX': 'http://localhost:8050'
        # pull queues
        'Watcher-MITx-6.0001r': !!null
        'Watcher-MITx-6.00x': !!null
        'open-ended': !!null
        'open-ended-message': !!null
        'test-pull': !!null
        'certificates': !!null
    {# residential only #}
    EDXAPP_AWS_STORAGE_BUCKET_NAME: mitx-storage-{{ purpose }}-{{ environment }}
    EDXAPP_IMPORT_EXPORT_BUCKET: "mitx-storage-{{ salt.grains.get('purpose') }}-{{ salt.grains.get('environment') }}"
    edxapp_course_static_dir: /edx/var/edxapp/course_static_dummy {# private variable, used to hack around the fact that we mount our course data via a shared file system (tmacey 2017-03-16) #}
    {# residential only, set this in order to verride the `fs_root` setting for module/content store, need to understand more fully how this gets used in GITHUB_REPO_ROOT (tmacey 2017/03/17) #}
    edxapp_course_data_dir: {{ GIT_REPO_DIR }}
    EDXAPP_CELERY_WORKERS:
      - queue: low
        service_variant: cms
        concurrency: 5
        monitor: True
      - queue: default
        service_variant: cms
        concurrency: 4
        monitor: True
      - queue: high
        service_variant: cms
        concurrency: 3
        monitor: True
      - queue: low
        service_variant: lms
        concurrency: 5
        monitor: True
      - queue: default
        service_variant: lms
        concurrency: 4
        monitor: True
      - queue: high
        service_variant: lms
        concurrency: 3
        monitor: True
      - queue: high_mem
        service_variant: lms
        concurrency: 1
        monitor: False
        max_tasks_per_child: 1
    {# multivariate #}
    EDXAPP_GOOGLE_ANALYTICS_ACCOUNT: {{ edx.edxapp_google_analytics_account }}
    EDXAPP_YOUTUBE_API_KEY: {{ salt.vault.read('secret-residential/global/edxapp-youtube-api-key').data.value }}
    EDXAPP_LMS_AUTH_EXTRA:
      REMOTE_GRADEBOOK_USER: {{ remote_gradebook.data.user }}
      REMOTE_GRADEBOOK_PASSWORD: {{ remote_gradebook.data.password }}
    EDXAPP_BUGS_EMAIL: mitx-support@mit.edu
    EDXAPP_LMS_ISSUER: "{{ EDXAPP_LMS_ISSUER }}"
    {# multivariate, only needed for current deployment. will be removed in favor of SAML (tmacey 2017/03/20) #}
    EDXAPP_CAS_ATTRIBUTE_PACKAGE: 'git+https://github.com/mitodl/mitx_cas_mapper#egg=mitx_cas_mapper'
    {# multivariate, only used for current residential #}
    EDXAPP_CAS_SERVER_URL: 'https://cas.mitx.mit.edu/cas'
    {# multivariate, only used for current residential #}
    EDXAPP_CAS_ATTRIBUTE_CALLBACK:
      module: mitx_cas_mapper
      function: populate_user
    {# multivariate, only used for current residential #}
    EDXAPP_CAS_EXTRA_LOGIN_PARAMS:
      provider: touchstone
      appname: MITx
    EDXAPP_CONTACT_EMAIL: mitx-support@mit.edu
    EDXAPP_DEFAULT_FEEDBACK_EMAIL: "{{ DEFAULT_FEEDBACK_EMAIL }}"
    EDXAPP_DEFAULT_FROM_EMAIL: "{{ DEFAULT_FROM_EMAIL }}"
    EDXAPP_GRADE_BUCKET: mitx-grades-{{ purpose }}-{{ environment }}
    EDXAPP_GRADE_ROOT_PATH: {{ edx.edxapp_aws_grades_root_path }}
    EDXAPP_GRADE_STORAGE_TYPE: S3
    EDXAPP_PLATFORM_NAME: MITx Residential
    EDXAPP_TECH_SUPPORT_EMAIL: mitx-support@mit.edu
    EDXAPP_CMS_ISSUER: "{{ EDXAPP_CMS_ISSUER }}"

    common_feature_flags: &common_feature_flags
      AUTH_USE_CAS: true
      REROUTE_ACTIVATION_EMAIL: mitx-support@mit.edu
      ENABLE_INSTRUCTOR_ANALYTICS: true
      ENABLE_INSTRUCTOR_LEGACY_DASHBOARD: true

    common_env_config: &common_env_config
      ADDL_INSTALLED_APPS:
        - ubcpi
      ADMINS:
      - ['MITx Stacktrace Recipients', 'cuddle-bunnies@mit.edu']
      BOOK_URL: ""
      SERVER_EMAIL: mitxmail@mit.edu
      TIME_ZONE_DISPLAYED_FOR_DEADLINES: "{{ TIME_ZONE }}"

    EDXAPP_CODE_JAIL_LIMITS:
      REALTIME: 3
      CPU: 3
      FSIZE: 1048576
      PROXY: 0
      VMEM: 536870912

    EDXAPP_LMS_ENV_EXTRA:
      <<: *common_env_config
      BULK_EMAIL_DEFAULT_FROM_EMAIL: mitx-support@mit.edu
      FEATURES:
        <<: *common_feature_flags
        ALLOW_COURSE_STAFF_GRADE_DOWNLOADS: true
        ENABLE_INSTRUCTOR_REMOTE_GRADEBOOK_CONTROLS: true
        ENABLE_S3_GRADE_DOWNLOADS: true
        ENABLE_SHOPPING_CART: true
        ENABLE_SYSADMIN_DASHBOARD: true
        ENABLE_INSTRUCTOR_EMAIL: true
        REMOTE_GRADEBOOK:
          URL: {{ remote_gradebook.data.url }}
          DEFAULT_NAME: !!null
      OAUTH_OIDC_ISSUER: "{{ EDXAPP_LMS_ISSUER }}"
      STUDENT_FILEUPLOAD_MAX_SIZE: "{{ edx.edxapp_max_upload_size * 1024 * 1024 }}"
    EDXAPP_CMS_ENV_EXTRA:
      <<: *common_env_config
      FEATURES:
        <<: *common_feature_flags
        STAFF_EMAIL: mitx-support@mit.edu
    EDXAPP_ENABLE_MOBILE_REST_API: True
    EDXAPP_ENABLE_SYSADMIN_DASHBOARD: True
    EDXAPP_FILE_UPLOAD_STORAGE_BUCKET_NAME: mitx-storage-{{ purpose }}-{{ environment }}
    EDXAPP_FILE_UPLOAD_STORAGE_PREFIX: {{ edx.edxapp_upload_storage_prefix }}
    OAUTH_OIDC_ISSUER: "{{ EDXAPP_CMS_ISSUER }}"
