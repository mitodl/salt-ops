{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}
{% set env_data = env_settings.environments[environment] %}
{% set xqwatcher_venv_base = '/edx/app/xqwatcher/venvs' %}

edx:
  ansible_vars:
   XQWATCHER_COURSES:
    {% for purpose, purpose_data in env_data.purposes.items() %}
    {% if 'residential' in purpose %}
    {% for queue_name in ['Watcher-MITx-6.0001r', 'Watcher-MITx-6.00x'] %}
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
          - __vault__::secret-residential/{{ environment }}/xqwatcher-xqueue-django-auth-{{ purpose }}>data>username
          - __vault__::secret-residential/{{ environment }}/xqwatcher-xqueue-django-auth-{{ purpose }}>data>password
    {% endfor %}
    - COURSE: mit-686x
      GIT_REPO: git@github.mit.edu:mitx/graders-mit-686x
      GIT_REF: master
      PYTHON_REQUIREMENTS:
        - name: numpy
          version: 1.14.0
        - name: pandas
          version: 0.22.0
        - name: scikit-image
          version: 0.13.1
        - name: scikit-learn
          version: 0.19.1
        - name: scipy
          version: 1.0.0
        - name: matplotlib
          version: 2.1.2
        - name: pytz
          version: 2018.4
        - name: networkx
          version: 2.1
        - name: cycler
          version: 0.10.0
        - name: decorator
          version: 4.3.0
        - name: Pillow
          version: 5.1.0
        - name: pyparsing
          version: 2.2.0
        - name: PyWavelets
          version: 0.5.2
        - name: six
          version: 1.11.0
      PYTHON_EXECUTABLE: /usr/bin/python3
      QUEUE_NAME: mitx-686xgrader
      QUEUE_CONFIG:
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
              grader_root: ../data/mit-686x/graders/
        AUTH:
         - __vault__::secret-residential/{{ environment }}/xqwatcher-xqueue-django-auth-{{ purpose }}>data>username
         - __vault__::secret-residential/{{ environment }}/xqwatcher-xqueue-django-auth-{{ purpose }}>data>password
    {% endif %}
    {% endfor %}


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
