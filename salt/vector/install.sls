{% from "vector/map.jinja" import vector with context %}


ensure_package_prerequisite_installations:
  pkg.installed:
    - pkgs: {{ vector.pkg_dependencies }}
    - update: true

install_vector_repo_key:
  cmd.run:
    - name: curl -1sLf "https://repositories.timber.io/public/vector/cfg/gpg/gpg.3543DB2D0A2BC4B8.key" | apt-key add -

update_apt_sources_list:
  pkgrepo.managed:
    - humanname: Vector
    - name: deb https://repositories.timber.io/public/vector/deb/{{ salt.grains.get('os', 'Debian')|lower }} {{ salt.grains.get('oscodename', 'stable') }} main
    - refresh_db: True

ensure_vector_package_state:
  pkg.installed:
    - name: vector
    - refresh: True
    - require:
      - pkgrepo: update_apt_sources_list

ensure_state_of_systemd_service_file:
  file.managed:
    - name: /etc/systemd/system/vector.service
    - source: salt://vector/files/vector.service
  cmd.wait:
    - name: systemctl daemon-reload
    - onchanges:
        - file: ensure_state_of_systemd_service_file
