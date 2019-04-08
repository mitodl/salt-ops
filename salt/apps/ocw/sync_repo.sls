
# The ocwcms working copy is /var/lib/ocwcms
# ... this has a sparse checkout of "plone/src" and "publishing".
# ... such that there are "plone" and "publishing" directory under /var/lib/ocwcms
# ... Plone wants to have /usr/local/Plone/zeocluster/src with subdirectories
#     ocw.contentimport, ocwhs.theme, ocw.publishing, ocw.theme, and ocw.types.
# ... so there is a symlink: /usr/local/Plone/zeocluster/src -> src_repo/plone/src
# ... And on the job queue server, /var/lib/ocwcms/publishing gets rsynced to
#     /mnt/ocwfileshare/OCWEngines.
#
# This state assumes that the working copy of the repo already exists in
# /var/lib/ocwcms.

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
    - force_checkout: True
    - force_clone: True
    - force_reset: True
    - force_fetch: True
    - update_head: True
    - user: root
    - identity: /root/.ssh/ocw_ssh_key

ensure_state_of_src_symlink:
  file.symlink:
    - name: /usr/local/Plone/zeocluster/src
    - target: /var/lib/ocwcms/plone/src
    - force: True
    - backupname: src_old

{% if salt['file.directory_exists']('/mnt/ocwfileshare/OCWEngines') %}

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

ensure_correct_ownership_of_OCWEngines_files:
  file.directory:
    - name: /mnt/ocwfileshare/OCWEngines
    - user: ocwuser
    - group: fsuser
    - recurse:
        - user
        - group

{% endif %}
