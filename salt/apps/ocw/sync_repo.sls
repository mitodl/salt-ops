
# The ocwcms working copy is /var/lib/ocwcms
# ... Plone wants to have /usr/local/Plone/zeocluster/src with subdirectories
#     ocw.contentimport, ocwhs.theme, ocw.publishing, ocw.theme, and ocw.types.
# ... so there is a symlink:
#     /usr/local/Plone/zeocluster/src -> /var/lib/ocwcms/plone/src
# ... And on the job queue server, /var/lib/ocwcms/publishing gets rsynced to
#     /mnt/ocwfileshare/OCWEngines.
#

{% set ocwcms_branch = salt.pillar.get('ocw:ocwcms_branch', 'master') %}
{% set roles = salt.grains.get('roles') %}

ensure_that_rsync_is_installed:
  pkg.installed:
    - name: rsync

add_private_github_ssh_key:
  file.managed:
    - name: /root/.ssh/ocw_ssh_key
    - contents_pillar: ocw:github_ssh_key
    - mode: 0600
    - makedirs: True

git_pull_ocwcms_working_copy:
  git.latest:
    - name: git@github.com:mitocw/ocwcms
    - target: /var/lib/ocwcms
    - rev: {{ ocwcms_branch }}
    - force_checkout: True
    - force_clone: True
    - force_reset: True
    - force_fetch: True
    - update_head: True
    - user: root
    - identity: /root/.ssh/ocw_ssh_key

{% if 'ocw-cms' in roles %}
ensure_state_of_src_symlink:
  file.symlink:
    - name: /usr/local/Plone/zeocluster/src
    - target: /var/lib/ocwcms/plone/src
    - force: True
    - backupname: src_old
{% endif %}

{% if 'ocw-origin' in roles %}

sync_ocwcms_web_directory:
  rsync.synchronized:
    - name: /var/www/ocw
    - prepare: True
    - source: /var/lib/ocwcms/web/
    - delete: False
    - update: True
    - additional_opts:
        - '-p'
        - '-t'
        - '-c'
        - '--delay-updates'

ensure_that_webroot_is_writable_by_fsuser:
  file.directory:
    - name: /var/www/ocw
    - user: fsuser
    - group: www-data

ensure_that_courses_dir_is_writable_by_fsuser:
  file.directory:
    - name: /var/www/ocw/courses
    - user: fsuser
    - group: www-data

ensure_that_highschool_dir_is_writable_by_fsuser:
  file.directory:
    - name: /var/www/ocw/high-school
    - user: fsuser
    - group: www-data

{% endif %}

# TODO: get rid of edxmapcopy.py in `ocwcms' (and transfer_edxmap_json.sh) and
# just let the state above handle it.


{% if 'ocw-cms' in roles %}

sync_ocwcms_publishing_dir_to_shared_fs:
  rsync.synchronized:
    - name: /mnt/ocwfileshare/OCWEngines
    - prepare: True
    # The ending "/" is very important:
    - source: /var/lib/ocwcms/publishing/
    - delete: False
    - update: True
    - additional_opts:
        - '-p'
        - '-t'
        - '-c'

ensure_correct_ownership_of_OCWEngines:
  file.directory:
    - name: /mnt/ocwfileshare/OCWEngines
    - user: ocwuser
    - group: fsuser
# This would be nice to have, but it can take hours to run, so I am commenting
# it out. -- Mark
#     - recurse:
#         - user
#         - group

ensure_correct_ownership_of_engines_working_dir:
  file.directory:
    - name: /mnt/ocwfileshare/OCWEngines/working
    - user: ocwuser
    - group: fsuser

ensure_correct_ownership_of_json_for_mobile_working_dir:
  file.directory:
    - name: /mnt/ocwfileshare/OCWEngines/working/json_for_mobile
    - user: plone
    - group: plone

{% endif %}
