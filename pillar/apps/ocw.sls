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
  mirror:
    fs_owner: ocwuser
    fs_group: ocwuser
    # rootdirectory corresponds to `rootdirectory' in the [Mirror] section of
    # the engine server's engines.conf. It's apparently where the final files
    # are put for being rsynced.
    rootdirectory: /data2/prod
    # data_dirs are directories that are hardcoded in
    # https://github.com/mitocw/ocwcms/blob/25f31dd2a15b6b658b0fa59d0cd8ebb8ebe0f7c7/mirror/scripts/ocw6%20Mirror%20Scripts/create_new_snapshot.sh
    data_dirs:
      - /ans15436
      - /data/InternetArchive
      - /data/prod/about
      - /data/prod/courses
      - /data/prod/give
      - /data/prod/educator
      - /data/prod/faculty
      - /data/prod/help
      - /data/prod/high-school
      - /data/prod/resources
      - /data/prod/support
      - /data/prod/terms
      - /data/prod/images
      - /data/prod/jsp
      - /data/prod/jw-player-free
      - /data/prod/mathjax
      - /data/prod/OcWeb
      - /data/prod/scripts
      - /data/prod/styles
      - /data/prod/webfonts
      - /data/prod/subscribe

{% if 'ocw-origin' in ROLES %}
schedule:
  pull_edx_courses_json:
    days: 1
    function: state.sls
    args:
      - apps.ocw.pull_edx_courses_json
{% endif %}
