install_datastax_pkg_repo:
  pkgrepo.managed:
    - humanname: Datastax Cassandra
    - name: deb http://debian.datastax.com/community stable main
    - gpgkey: https://debian.datastax.com/debian/repo_key
    - refresh_db: True
    - key_url: {{ elasticsearch.gpg_key }}

install_cassandra_package:
  pkg.installed:
    - name: cassandra=1.2.19
    - require: install_datastax_pkg_repo

prevent_upgrade_of_cassandra:
  module.run:
    - name: pkg.set_selections
    - selection:
        hold:
          - cassandra
