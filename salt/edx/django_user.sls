{% set django_superuser = salt.pillar.get('devstack:edx:django:django_superuser', 'devstack') %}
{% set django_superuser_password = salt.pillar.get('devstack:edx:django:django_superuser_password', 'changeme') %}

create_django_staff_account:
  cmd.run:
    - name: python manage.py lms create_user -u {{ django_superuser }} -e {{ django_superuser }}@example.com -p {{ django_superuser_password }} --staff --settings=aws
    - cwd: /edx/app/edxapp/edx-platform/
    - env: /edx/app/edxapp/edxapp_env
    - runas: edxapp
