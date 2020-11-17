{% set env_settings = salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml", dest=None)|load_yaml %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}
{% set env_data = env_settings.environments[environment] %}
{% set xqwatcher_venv_base = '/edx/app/xqwatcher/venvs' %}
{% set python3_version = 'python3.8' %}
{% set queue_name = 'mitx-6S082grader' %}

edx:
  xqwatcher:
    grader_requirements:
      - numpy
  ansible_vars:
   XQWATCHER_COURSES:
    {% for purpose, purpose_data in env_data.purposes.items() %}
    {% if 'residential' in purpose %}
    - COURSE: "mit-6S082-{{ purpose }}-{{ queue_name }}"
      GIT_REPO: git@github.mit.edu:mitx/graders-mit-6S082r
      GIT_REF: {{ purpose_data.versions.xqwatcher_courses }}
      PYTHON_REQUIREMENTS:
        - name: numpy
          version: 1.17.2
        - name: scikit-learn
          version: 0.21.3
        - name: scipy
          version: 1.3.1
      PYTHON_EXECUTABLE: /usr/bin/{{ python3_version }}
      QUEUE_NAME: {{ queue_name }}
      QUEUE_CONFIG:
        AUTH:
          - __vault__::secret-residential/{{ environment }}/xqwatcher-xqueue-django-auth-{{ purpose }}>data>username
          - __vault__::secret-residential/{{ environment }}/xqwatcher-xqueue-django-auth-{{ purpose }}>data>password
        SERVER: http://xqueue-{{ purpose }}.service.consul:18040
        CONNECTIONS: 5
        HANDLERS:
          - HANDLER: 'xqueue_watcher.jailedgrader.JailedGrader'
            CODEJAIL:
              name: mit-6S082
              user: mit-6S082
              lang: python3
              bin_path: "{{ xqwatcher_venv_base }}/mit-6S082/bin/python"
            KWARGS:
              grader_root: ../data/mit-6S082-{{ purpose }}-{{ queue_name }}/
    {% endif %}
    {% endfor %}


schedule:
  {% for purpose, purpose_data in env_data.purposes.items() %}
  {% if purpose_data.business_unit == 'residential' %}
  update_live_grader_for_{{ purpose }}_with_{{ queue_name }}_queue:
    function: git.pull
    minutes: 5
    args:
      - /edx/app/xqwatcher/data/mit-6S082-{{ purpose }}-{{ queue_name }}/
    kwargs:
      identity: /edx/app/xqwatcher/.ssh/xqwatcher-courses
  {% endif %}
  {% endfor %}
