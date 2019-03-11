{% set ENVIRONMENT = salt.grains.get('environment') %}

ocw:
  db_username: __vault__::secret-ocw/{{ ENVIRONMENT }}/db>data>username
  db_password: __vault__::secret-ocw/{{ ENVIRONMENT }}/db>data>password
  cms_username: __vault__::secret-ocw/{{ ENVIRONMENT }}/cms>data>username
  cms_password: __vault__::secret-ocw/{{ ENVIRONMENT }}/cms>data>password
  dspace_connection_user: __vault__::secret-ocw/{{ ENVIRONMENT }}/dspace/test>data>username
  dspace_connection_password: __vault__::secret-ocw/{{ ENVIRONMENT }}/dspace/test>data>password
  github_ssh_key: __vault__::secret-ocw/global/github/ssh>data>value
