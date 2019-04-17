{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set ROLES = salt.grains.get('roles') %}

ocw:
  db_username: __vault__::secret-ocw/{{ ENVIRONMENT }}/db>data>username
  db_password: __vault__::secret-ocw/{{ ENVIRONMENT }}/db>data>password
  cms_username: __vault__::secret-ocw/{{ ENVIRONMENT }}/cms>data>username
  cms_password: __vault__::secret-ocw/{{ ENVIRONMENT }}/cms>data>password
  dspace_connection_user: __vault__::secret-ocw/{{ ENVIRONMENT }}/dspace/test>data>username
  dspace_connection_password: __vault__::secret-ocw/{{ ENVIRONMENT }}/dspace/test>data>password
  github_ssh_key: __vault__::secret-ocw/global/github/ssh-deploy-key>data>value

{% if 'ocw-origin' in ROLES %}
schedule:
  pull_edx_courses_json:
    days: 1
    function: state.sls
    args:
      - apps.ocw.pull_edx_courses_json
{% endif %}
