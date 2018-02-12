{% set django_staff_user = salt.pillar.get('devstack:edx:django:django_staff_user', 'devstack') %}
{% set django_staff_password = salt.pillar.get('devstack:edx:django:django_staff_password', 'changeme') %}

create_django_staff_account:
  cmd.run:
    - name: /edx/bin/python.edxapp /edx/bin/manage.edxapp lms create_user -u {{ django_staff_user }} -e {{ django_staff_user }}@example.com -p {{ django_staff_password }} --staff --settings=aws
    - cwd: /edx/app/edxapp/edx-platform/
    - runas: edxapp
