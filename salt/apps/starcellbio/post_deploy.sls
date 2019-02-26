{% set app_dir = '/opt/{0}'.format(salt.pillar.get('django:app_name')) %}
{% set django = salt.pillar.get('django') %}

populate_database_with_seed_data:
  module.run:
    - name: django.loaddata
    - settings_module: {{ django.settings_module }}
    - pythonpath: {{ app_dir }}
    - fixtures: auth,backend,courses,assignments,studentassignments
    - bin_env: {{ django.django_admin_path }}
    - runas: deploy
    - env: {{ django.get('environment', {})|tojson }}
    {% if django.automatic_migrations %}
    - require:
        - module: migrate_database
    {% endif %}

compile_static_files:
  cmd.run:
    - name: /usr/local/pyenv/shims/python html_app/build.py
    - cwd: {{ app_dir }}
    - shell: /bin/bash
    - user: deploy
    - prepend_path: {{ app_dir }}/node_modules/.bin
    - env:
        PROJECT_HOME: {{ app_dir }}/html_app
