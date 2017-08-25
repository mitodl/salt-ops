{% set django_superuser = salt.pillar.get('devstack:edx:django:django_staff_user', 'devstack') %}
{% set django_superuser_password = salt.pillar.get('devstack:edx:django:django_staff_password', 'changeme') %}

create_django_staff_account:
  cmd.run:
    - name: python manage.py lms create_user -u {{ django_staff_user }} -e {{ django_staff_user }}@example.com -p {{ django_staff_password }} --staff --settings=aws
    - cwd: /edx/app/edxapp/edx-platform/
    - env: '/edx/app/edxapp/edxapp_env'
    - runas: edxapp
