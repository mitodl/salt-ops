{% set env_settings = salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml", dest=None)|load_yaml %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}
{% set env_data = env_settings.environments[environment] %}
{% set xqwatcher_venv_base = '/edx/app/xqwatcher/venvs' %}
{% set python3_version = 'python3.8' %}

edx:
  xqwatcher:
    grader_requirements:
      - future
      - numpy
      - 'https://download.pytorch.org/whl/cpu/torch-1.7.0%2Bcpu-cp38-cp38-linux_x86_64.whl#egg=pytorch'
  ansible_vars:
    XQWATCHER_COURSES:
      - COURSE: mit-686x-mooc
        GIT_REPO: git@github.mit.edu:mitx/graders-mit-686x
        GIT_REF: master
        PYTHON_REQUIREMENTS:
          - name: numpy
            version: 1.19.4
          - name: pandas
            version: 1.1.4
          - name: scikit-image
            version: 0.17.2
          - name: scikit-learn
            version: 0.23.2
          - name: scipy
            version: 1.5.4
          - name: matplotlib
            version: 3.3.3
          - name: pytz
            version: 2019.3
          - name: networkx
            version: 2.5
          - name: cycler
            version: 0.10.0
          - name: decorator
            version: 4.4.2
          - name: Pillow
            version: 8.0.1
          - name: pyparsing
            version: 2.4.7
          - name: PyWavelets
            version: 1.1.1
          - name: six
            version: 1.15.0
          - name: 'https://download.pytorch.org/whl/cpu/torch-1.7.0%2Bcpu-cp38-cp38-linux_x86_64.whl#egg=pytorch'
            version: 1.7.0
        PYTHON_EXECUTABLE: /usr/bin/{{ python3_version }}
        QUEUE_NAME: mitx-686xgrader
        QUEUE_CONFIG:
          AUTH:
            - __vault__::secret-residential/global/course-686x-grader-xqueue-credentials>data>username
            - __vault__::secret-residential/global/course-686x-grader-xqueue-credentials>data>password
          SERVER: https://xqueue.edx.org
          CONNECTIONS: 5
          HANDLERS:
            - HANDLER: 'xqueue_watcher.jailedgrader.JailedGrader'
              CODEJAIL:
                name: mit-686x-mooc
                user: mit-686x-mooc
                lang: python3
                bin_path: '{% raw %}{{ xqwatcher_venv_base }}{% endraw %}/mit-686x-mooc/bin/python'
                limits:
                  REALTIME: 10
                  CPU: 5
                  FSIZE: 1048576
                  PROXY: 0
                  NPROC: 15
              KWARGS:
                grader_root: ../data/mit-686x-mooc/graders/
      {% for purpose, purpose_data in env_data.purposes.items() %}
      {% if 'residential' in purpose %}
      - COURSE: mit-686x-{{ purpose }}
        GIT_REPO: git@github.mit.edu:mitx/graders-mit-686x
        GIT_REF: master
        PYTHON_REQUIREMENTS:
          - name: numpy
            version: 1.19.4
          - name: pandas
            version: 1.1.4
          - name: scikit-image
            version: 0.17.2
          - name: scikit-learn
            version: 0.23.2
          - name: scipy
            version: 1.5.4
          - name: matplotlib
            version: 3.3.3
          - name: pytz
            version: 2019.3
          - name: networkx
            version: 2.5
          - name: cycler
            version: 0.10.0
          - name: decorator
            version: 4.4.2
          - name: Pillow
            version: 8.0.1
          - name: pyparsing
            version: 2.4.7
          - name: PyWavelets
            version: 1.1.1
          - name: six
            version: 1.15.0
          - name: 'https://download.pytorch.org/whl/cpu/torch-1.7.0%2Bcpu-cp38-cp38-linux_x86_64.whl#egg=pytorch'
            version: 1.7.0
        PYTHON_EXECUTABLE: /usr/bin/{{ python3_version }}
        QUEUE_NAME: mitx-686xgrader
        QUEUE_CONFIG:
          AUTH:
            - __vault__::secret-residential/{{ environment }}/xqwatcher-xqueue-django-auth-{{ purpose }}>data>username
            - __vault__::secret-residential/{{ environment }}/xqwatcher-xqueue-django-auth-{{ purpose }}>data>password
          SERVER: 'http://xqueue-{{ purpose }}.service.consul:18040'
          CONNECTIONS: 5
          HANDLERS:
            - HANDLER: 'xqueue_watcher.jailedgrader.JailedGrader'
              CODEJAIL:
                name: mit-686x
                user: mit-686x
                lang: python3
                bin_path: '{% raw %}{{ xqwatcher_venv_base }}{% endraw %}/mit-686x/bin/python'
                limits:
                  REALTIME: 10
                  CPU: 5
                  FSIZE: 1048576
                  PROXY: 0
                  NPROC: 15
              KWARGS:
                grader_root: ../data/mit-686x-{{ purpose }}/graders/
      {% endif %}
      {% endfor %}


schedule:
  {% for purpose, purpose_data in env_data.purposes.items() %}
  {% if purpose_data.business_unit == 'residential' %}
  update_live_686_grader_for_{{ purpose }}:
    function: git.pull
    minutes: 5
    args:
      - /edx/app/xqwatcher/data/mit-686x-{{ purpose }}/
    kwargs:
      identity: /edx/app/xqwatcher/.ssh/xqwatcher-courses
  {% endif %}
  {% endfor %}
  update_live_grader_for_mit_686x_mooc_queue:
    function: git.pull
    minutes: 5
    args:
      - /edx/app/xqwatcher/data/mit-686x-mooc
    kwargs:
      identity: /edx/app/xqwatcher/.ssh/xqwatcher-courses
