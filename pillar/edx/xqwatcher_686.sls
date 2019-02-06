{% set xqwatcher_venv_base = '/edx/app/xqwatcher/venvs' %}

edx:
  ansible_vars:
   XQWATCHER_COURSES:
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
           - __vault__::secret-residential/global/course-686x-grader-xqueue-credentials>data>username
           - __vault__::secret-residential/global/course-686x-grader-xqueue-credentials>data>password

schedule:
  update_live_grader_for_mit_686x_queue:
    function: git.pull
    minutes: 5
    args:
      - /edx/app/xqwatcher/data/mit-686x
    kwargs:
      identity: /edx/app/xqwatcher/.ssh/xqwatcher-courses
  restart_weekly_to_refresh_login:
    function: supervisord.restart
    days: 7
    args:
      - xqwatcher
    kwargs:
      bin_env: /edx/bin/supervisorctl
