install_repo_key:
  cmd.run:
    - name: curl -L https://debian.datastax.com/debian/repo_key | apt-key add -

install_datastax_pkg_repo:
  pkgrepo.managed:
    - humanname: Datastax Cassandra
    - name: deb http://debian.datastax.com/community stable main
    - refresh_db: True

install_cassandra_package:
  pkg.installed:
    - name: cassandra
    - hold: True
    - version: 1.2.19
    - refresh: True
    - require:
        - pkgrepo: install_datastax_pkg_repo
