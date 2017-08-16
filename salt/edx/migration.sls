{% set edxapp_bin = '/edx/app/edxapp/venvs/edxapp/bin/' %}
{% set migrations = ['lms', 'cms'] %}

run_edxapp_{{  }}_migrations:
  cmd.run:
    - name: '{{ edxapp_bin }}python manage.py lms migrate --noinput --fake-initial --settings=aws'
    - cwd: /edx/app/edxapp/edx-platform
    - runas: edxapp
