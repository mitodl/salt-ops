{% set django_superuser_account = salt.pillar.get('devstack:edx:django:django_superuser_account', 'devstack') %}
{% set django_superuser_password = salt.pillar.get('devstack:edx:django:django_superuser_password', 'changeme') %}

create_django_superuser_account:
  cmd.run:
    - name: /edx/bin/python.edxapp /edx/bin/manage.edxapp lms manage_user {{ django_superuser_account }} {{ django_superuser_account }}@example.com --staff --superuser --settings=devstack
    - cwd: /edx/app/edxapp/edx-platform/
    - runas: edxapp

create_django_staff_account:
  cmd.run:
    - name: /edx/bin/python.edxapp /edx/bin/manage.edxapp lms create_user -u staff -e staff@example.com -p {{ django_superuser_password }} --staff --settings=devstack
    - cwd: /edx/app/edxapp/edx-platform/
    - runas: edxapp

{% for account in [audit, honor, verified] %}
create_django_{{ account }}_account:
  cmd.run:
    - name: /edx/bin/python.edxapp /edx/bin/manage.edxapp lms create_user -u {{ account }} -e {{ account }}@example.com -p {{ django_superuser_password }} --settings=devstack
    - cwd: /edx/app/edxapp/edx-platform/
    - runas: edxapp
{% endfor %}