install_datastax_pkg_repo:
  pkgrepo.managed:
    - humanname: Datastax Cassandra
    - name: deb http://debian.datastax.com/community stable main
    - refresh_db: True
    - key_url: https://debian.datastax.com/debian/repo_key

install_cassandra_package:
  pkg.installed:
    - name: cassandra
    - hold: True
    - version: 1.2.19
    - refresh: True
    - require:
        - pkgrepo: install_datastax_pkg_repo
