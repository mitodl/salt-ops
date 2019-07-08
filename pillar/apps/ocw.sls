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
    # https://github.com/mitocw/ocwcms/blob/d98a4919813cd97103dce3ee1a7a41ae359eac15/mirror/scripts/create_new_snapshot.sh
    data_dirs:
      - /ans15436
      - /data2/InternetArchive
      - /data2/prod/about
      - /data2/prod/courses
      - /data2/prod/give
      - /data2/prod/educator
      - /data2/prod/faculty
      - /data2/prod/help
      - /data2/prod/high-school
      - /data2/prod/resources
      - /data2/prod/support
      - /data2/prod/terms
      - /data2/prod/images
      - /data2/prod/jsp
      - /data2/prod/jw-player-free
      - /data2/prod/mathjax
      - /data2/prod/OcWeb
      - /data2/prod/scripts
      - /data2/prod/styles
      - /data2/prod/webfonts
      - /data2/prod/subscribe
  engines:
    basedir: /mnt/ocwfileshare/OCWEngines
    cron_log_dir: /var/log/engines-cron

{% if 'ocw-origin' in ROLES %}
schedule:
  pull_edx_courses_json:
    days: 1
    function: state.sls
    args:
      - apps.ocw.pull_edx_courses_json
{% endif %}
