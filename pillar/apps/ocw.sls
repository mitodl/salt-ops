{% set ENVIRONMENT = salt.grains.get('ocw-environment') %}
{% set ROLES = salt.grains.get('roles') %}

ocw:
  db_username: __vault__::secret-open-courseware/{{ ENVIRONMENT }}/db>data>username
  db_password: __vault__::secret-open-courseware/{{ ENVIRONMENT }}/db>data>password
  cms_username: __vault__::secret-open-courseware/{{ ENVIRONMENT }}/cms>data>username
  cms_password: __vault__::secret-open-courseware/{{ ENVIRONMENT }}/cms>data>password
  dspace_test_connection_user: __vault__::secret-open-courseware/{{ ENVIRONMENT }}/dspace/test>data>username
  dspace_test_connection_password: __vault__::secret-open-courseware/{{ ENVIRONMENT }}/dspace/test>data>password
  dspace_prod_connection_user: __vault__::secret-open-courseware/{{ ENVIRONMENT }}/dspace/prod>data>username
  dspace_prod_connection_password: __vault__::secret-open-courseware/{{ ENVIRONMENT }}/dspace/prod>data>password
  github_ssh_key: __vault__::secret-open-courseware/global/github/ssh-deploy-key>data>value
  cron_mailto: mitx-devops@mit.edu

{% if 'ocw-origin' in ROLES %}
schedule:
  pull_edx_courses_json:
    days: 1
    function: state.sls
    args:
      - apps.ocw.pull_edx_courses_json
{% endif %}
