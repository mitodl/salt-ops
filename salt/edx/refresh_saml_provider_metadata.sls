run_saml_pull:
  cmd.run:
    - name: '/edx/bin/python.edxapp ./manage.py lms saml --pull --settings=production'
    - cwd: /edx/app/edxapp/edx-platform
    - runas: www-data
