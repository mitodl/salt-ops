
symlink_sitemap_sh:
  file.symlink:
    - name: /var/https/tomcat-4.0.6/webapps/sitemap.sh
    - target: /var/lib/ocwcms/publishing/sitemap.sh
    - force: True
    - owner: root
    - group: root
    - makedirs: True

symlink_listzips_sh:
  file.symlink:
    - name: /var/https/tomcat-4.0.6/webapps/listzips.sh
    - target: /var/lib/ocwcms/publishing/listzips.sh
    - force: True
    - owner: root
    - group: root
    - makedirs: True
