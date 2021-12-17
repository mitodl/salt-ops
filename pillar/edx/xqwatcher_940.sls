{% set env_settings = salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml", dest=None)|load_yaml %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}
{% set env_data = env_settings.environments[environment] %}
{% set xqwatcher_venv_base = '/edx/app/xqwatcher/venvs' %}
{% set python3_version = 'python3.8' %}
{% set queue_name = 'mitx-940grader' %}
{% set env_map = {
  "mitx": "production",
  "mitx-staging": "master"
} %}

{% set watcher_git_ref = env_map[environment.rsplit("-", 1)[-1]] %}
{% set env_prefix = environment.rsplit("-", 1)[-1] %}

edx:
  xqwatcher:
    grader_requirements:
      - numpy
  ansible_vars:
   XQWATCHER_COURSES:
    - COURSE: "mit-940"
      GIT_REPO: git@github.mit.edu:mitx/graders-mit-940r
      GIT_REF: {{ watcher_git_ref }}
      PYTHON_REQUIREMENTS:
        - name: numpy
          version: 1.19.4
        - name: scipy
          version: 1.5.4
        - name: pandas
          version: 1.1.4
        - name: seaborn
          version: 0.11.0
      PYTHON_EXECUTABLE: /usr/bin/{{ python3_version }}
      QUEUE_NAME: {{ queue_name }}
      QUEUE_CONFIG:
        AUTH:
          - xqwatcher
          - __vault__::secret-{{ env_prefix }}/edx-xqueue>data>xqwatcher_password
        SERVER: http://xqueue.service.consul:18040
        CONNECTIONS: 5
        HANDLERS:
          - HANDLER: 'xqueue_watcher.jailedgrader.JailedGrader'
            CODEJAIL:
              name: mit-940
              user: mit-940
              lang: python3
              bin_path: "{{ xqwatcher_venv_base }}/mit-940/bin/python"
            KWARGS:
              grader_root: ../data/mit-940/


schedule:
  update_live_grader_for:
    function: git.pull
    minutes: 5
    args:
      - /edx/app/xqwatcher/data/mit-940/
    kwargs:
      identity: /edx/app/xqwatcher/.ssh/xqwatcher-courses
