{% set edxapp_bin = '/edx/app/edxapp/venvs/edxapp/bin/' %}
{% set migrations = ['lms', 'cms'] %}

{% for migration in migrations %}
run_edxapp_{{ migration }}_migrations:
  cmd.run:
    - name: '{{ edxapp_bin }}python manage.py {{ migration }} migrate --noinput --fake-initial --settings=aws'
    - cwd: /edx/app/edxapp/edx-platform
    - runas: edxapp
{% endfor %}

{% if salt['file.directory_exists']('/edx/app/edxapp/venvs/edxapp/rapid_response') %}
run_rapid_response_xblock_migration:
  cmd.run:
    - name: '{{ edxapp_bin }}python manage.py lms makemigrations rapid_response_xblock --settings=aws'
    - cwd: /edx/app/edxapp/edx-platform
    - runas: edxapp
{% endif %}
