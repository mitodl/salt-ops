{% set edxapp_bin = '/edx/app/edxapp/venvs/edxapp/bin/python' %}
{% set migrations = ['lms', 'cms'] %}

{% for migration in migrations %}
run_make_migrations_in_{{ migration }}_for_django_plugins:
  cmd.run:
    - name: '{{ edxapp_bin }} manage.py {{ migration }} makemigrations'
    - cwd: /edx/app/edxapp/edx-platform
    - runas: edxapp

run_edxapp_{{ migration }}_migrations:
  cmd.run:
    - name: '{{ edxapp_bin }} manage.py {{ migration }} migrate --noinput --fake-initial --settings=production'
    - cwd: /edx/app/edxapp/edx-platform
    - runas: edxapp
{% endfor %}
