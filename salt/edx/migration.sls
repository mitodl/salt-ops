{% set edxapp_bin = '/edx/app/edxapp/venvs/edxapp/bin/' %}
{% set migrations = ['lms', 'cms'] %}

{% for migration in migrations %}
run_edxapp_{{ migration }}_migrations:
  cmd.run:
    - name: '{{ edxapp_bin }}python manage.py {{ migration }} migrate --noinput --fake-initial --settings=aws'
    - cwd: /edx/app/edxapp/edx-platform
    - runas: edxapp
{% endfor %}
