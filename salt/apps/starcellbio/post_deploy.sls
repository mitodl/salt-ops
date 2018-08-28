{% set app_dir = '/opt/{0}'.format(salt.pillar.get('django:app_name')) %}

populate_database_with_seed_data:
  module.run:
    - name: django.loaddata
    - settings_module: {{ django.settings_module }}
    - pythonpath: {{ app_dir }}
    - fixtures: auth,backend,courses,assignments,studentassignments
    - bin_env: {{ django.django_admin_path }}
    - runas: {{ django.user }}
    - env: {{ django.get('environment', {}) }}

compile_static_files:
  cmd.run:
    - name: python build.py
    - cwd: {{ app_dir }}
    - user: deploy
    - env:
        PROJECT_HOME: {{ app_dir }}/html_app
        PATH: {{ app_dir }}/node_modules/.bin:{{ grains.get('path') }}
