

ensure_state_of_legacy_tomcat_dir:
  file.directory:
    - name: /var/https/tomcat-4.0.6
    - user: root
    - group: root
    - dir_mode: '0755'

ensure_state_of_tomcat_webapps_symlink:
  file.symlink:
    - name: /var/https/tomcat-4.0.6/webapps
    - target: /var/www/ocw
    - owner: root
    - group: root

# The following two files are symlinked in order to avoid making changes
# to the scripts in `ocwcms', in case the scripts are copied back to the
# original servers. When we make the break and shut those servers down, the
# scripts should run out of the /var/lib/ocwcms directory and these symlinks
# should be removed. The script `publishing/run_aka_scripts.sh' in the `ocwcms'
# repo should also be modified.

symlink_sitemap_sh:
  file.symlink:
    - name: /var/www/ocw/sitemap.sh
    - target: /var/lib/ocwcms/publishing/sitemap.sh
    - force: True
    - owner: root
    - group: root
    - makedirs: True

symlink_listzips_sh:
  file.symlink:
    - name: /var/www/ocw/listzips.sh
    - target: /var/lib/ocwcms/publishing/listzips.sh
    - force: True
    - owner: root
    - group: root
    - makedirs: True
