{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}
{% set env_data = env_settings.environments[environment] %}
{% set xqwatcher_venv_base = '/edx/app/xqwatcher/venvs' %}
{% set python3_version = 'python3.7' %}

edx:
  ansible_vars:
    XQWATCHER_COURSES:
      - COURSE: mit-686x-mooc
        GIT_REPO: git@github.mit.edu:mitx/graders-mit-686x
        GIT_REF: master
        PYTHON_REQUIREMENTS:
          - name: numpy
            version: 1.17.2
          - name: pandas
            version: 0.25.1
          - name: scikit-image
            version: 0.15.0
          - name: scikit-learn
            version: 0.21.3
          - name: scipy
            version: 1.3.1
          - name: matplotlib
            version: 3.1.1
          - name: pytz
            version: 2019.2
          - name: networkx
            version: 2.3
          - name: cycler
            version: 0.10.0
          - name: decorator
            version: 4.4.0
          - name: Pillow
            version: 6.1.0
          - name: pyparsing
            version: 2.4.2
          - name: PyWavelets
            version: 1.0.3
          - name: six
            version: 1.11.0
          - name: https://download.pytorch.org/whl/cpu/torch-1.0.1.post2-cp37-cp37m-linux_x86_64.whl#egg=pytorch
            version: 1.0.1
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
              KWARGS:
                grader_root: ../data/mit-686x-mooc/graders/
      {% for purpose, purpose_data in env_data.purposes.items() %}
      {% if 'residential' in purpose %}
      - COURSE: mit-686x-{{ purpose }}
        GIT_REPO: git@github.mit.edu:mitx/graders-mit-686x
        GIT_REF: master
        PYTHON_REQUIREMENTS:
          - name: numpy
            version: 1.17.2
          - name: pandas
            version: 0.25.1
          - name: scikit-image
            version: 0.15.0
          - name: scikit-learn
            version: 0.21.3
          - name: scipy
            version: 1.3.1
          - name: matplotlib
            version: 3.1.1
          - name: pytz
            version: 2019.2
          - name: networkx
            version: 2.3
          - name: cycler
            version: 0.10.0
          - name: decorator
            version: 4.4.0
          - name: Pillow
            version: 6.1.0
          - name: pyparsing
            version: 2.4.2
          - name: PyWavelets
            version: 1.0.3
          - name: six
            version: 1.11.0
          - name: https://download.pytorch.org/whl/cpu/torch-1.0.1.post2-cp37-cp37m-linux_x86_64.whl#egg=pytorch
            version: 1.0.1
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
