#!jinja|yaml|gpg
{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}
{% set env_data = env_settings.environments[environment] %}
{% set git_ssh_key = salt.vault.read('secret-residential/global/xqueue_watcher_git_ssh').data.value %}
{% set xqwatcher_venv_base = '/edx/app/xqwatcher/venvs' %}

schedule:
  {% for purpose, purpose_data in env_data.purposes.items() %}
  {% if purpose_data.business_unit == 'residential' %}
  {% for queue_name in ['Watcher-MITx-6.0001r', 'Watcher-MITx-6.00x'] %}
  update_live_grader_for_{{ purpose }}_with_{{ queue_name }}_queue:
    function: git.pull
    minutes: 5
    args:
      - /edx/app/xqwatcher/data/mit-600x-{{ purpose }}-{{ queue_name }}/
    kwargs:
      identity: /edx/app/xqwatcher/.ssh/xqwatcher-courses
  {% endfor %}
  {% endif %}
  {% endfor %}
  restart_weekly_to_refresh_login:
    function: supervisord.restart
    days: 7
    args:
      - xqwatcher
    kwargs:
      bin_env: /edx/bin/supervisorctl

edx:
  xqwatcher:
    logconfig:
      version: 1
      disable_existing_loggers: False
      formatters:
        default:
          format: '%(asctime)s - %(filename)s:%(lineno)d -- %(funcName)s [%(levelname)s]: %(message)s'
      handlers:
        console:
          class: logging.StreamHandler
          formatter: default
          level: DEBUG
        syslog:
          class: logging.handlers.SysLogHandler
          formatter: default
          level: INFO
          address: /dev/log
      loggers:
        "":
          level: INFO
          handlers:
            - syslog
            - console
  config:
    repo: https://github.com/mitodl/configuration.git
    branch: open-release/ginkgo.master
  playbooks:
    - 'edx-east/xqwatcher.yml'
  ansible_vars:
    XQWATCHER_VERSION: 20ab9e6d645b0b8850f14db558499e62e554d8a2
    XQWATCHER_GIT_IDENTITY: |
      {{ git_ssh_key|indent(6)}}
    XQWATCHER_COURSES:
      {% for purpose, purpose_data in env_data.purposes.items() %}
      {% if 'residential' in purpose %}
      {% for queue_name in ['Watcher-MITx-6.0001r', 'Watcher-MITx-6.00x'] %}
      {% set xqwatcher_xqueue_creds = salt.vault.read(
          'secret-{business_unit}/{env}/xqwatcher-xqueue-django-auth-{purpose}'.format(
              business_unit='residential',
              env=environment,
              purpose=purpose)) %}
      - COURSE: "mit-600x-{{ purpose }}-{{ queue_name }}"
        GIT_REPO: git@github.com:mitodl/graders-mit-600x
        GIT_REF: {{ purpose_data.versions.xqwatcher_courses }}
        PYTHON_REQUIREMENTS:
          - name: numpy
            version: 1.12.1
          - name: scikit-learn
            version: 0.19.1
          - name: scipy
            version: 1.0.0
        PYTHON_EXECUTABLE: /usr/bin/python3
        QUEUE_NAME: {{ queue_name }}
        QUEUE_CONFIG:
          SERVER: http://xqueue-{{ purpose }}.service.consul:18040
          CONNECTIONS: 5
          HANDLERS:
            - HANDLER: 'xqueue_watcher.jailedgrader.JailedGrader'
              CODEJAIL:
                name: mit-600x
                user: mit-600x
                lang: python3
                bin_path: '{% raw %}{{ xqwatcher_venv_base }}{% endraw %}/mit-600x/bin/python'
              KWARGS:
                grader_root: ../data/mit-600x-{{ purpose }}-{{ queue_name }}/graders/python3graders/
          AUTH:
            - {{ xqwatcher_xqueue_creds.data.username }}
            - {{ xqwatcher_xqueue_creds.data.password }}
      {% endfor %}
      {% endif %}
      {% endfor %}
      {% set xqueue_686_creds = salt.vault.read('secret-residential/global/course-686x-grader-xqueue-credentials') %}
      - COURSE: mit-686x
        GIT_REPO: git@github.mit.edu:mitx/graders-mit-686x
        GIT_REF: master
        PYTHON_REQUIREMENTS:
          - name: numpy
            version: 1.14.0
          - name: numpydoc
            version: 0.7.0
          - name: pandas
            version: 0.22.0
          - name: pandocfilters
            version: 1.4.2
          - name: scikit-image
            version: 0.13.1
          - name: scikit-learn
            version: 0.19.1
          - name: scipy
            version: 1.0.0
          - name: matplotlib
            version: 2.1.2
        PYTHON_EXECUTABLE: /usr/bin/python3
        QUEUE_NAME: mitx-686xgrader
        QUEUE_CONFIG:
          SERVER: https://xqueue.edx.org
          CONNECTIONS: 5
          HANDLERS:
            - HANDLER: 'xqueue_watcher.jailedgrader.JailedGrader'
              CODEJAIL:
                name: mit-686x
                user: mit-686x
                lang: python3
                bin_path: '{% raw %}{{ xqwatcher_venv_base }}{% endraw %}/mit-686x/bin/python'
              KWARGS:
                grader_root: ../data/mit-686x/graders/
          AUTH:
            - {{ xqueue_686_creds.data.username }}
            - {{ xqueue_686_creds.data.password }}
    XQWATCHER_CONFIG:
      POLL_TIME: 10
      REQUESTS_TIMEOUT: 1.5
    XQWATCHER_REPOS:
      - PROTOCOL: "https"
        DOMAIN: "github.com"
        PATH: "mitodl"
        REPO: "xqueue-watcher.git"
        VERSION: "20ab9e6d645b0b8850f14db558499e62e554d8a2"
        DESTINATION: "/edx/app/xqwatcher/src"
        SSH_KEY: |
          {{ git_ssh_key|indent(10)}}
