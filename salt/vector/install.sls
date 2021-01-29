ensure_package_prerequisite_installations:
  pkg.installed:
    - pkgs:
        - debian-keyring
        - debian-archive-keyring
        - apt-transport-https
        - ca-certificates
        - gnupg

install_vector_repo_key:
  cmd.run:
    - name: curl -1sLf "https://repositories.timber.io/public/vector/cfg/gpg/gpg.3543DB2D0A2BC4B8.key" | apt-key add -

update_apt_sources_list:
  pkgrepo.managed:
    - humanname: Vector
    - name: deb https://repositories.timber.io/public/vector/deb/debian {{ salt.grains.get('oscodename', 'stable') }} main
    - refresh_db: True

ensure_vector_package_state:
  pkg.installed:
    - name: vector
    - refresh: True
    - require:
      - cmd: install_vector_repo

ensure_state_of_systemd_service_file:
  file.managed:
    - name: /etc/systemd/system/vector.service
    - source: salt://vector/files/vector.service
  cmd.wait:
    - name: systemctl daemon-reload
    - onchanges:
        - file: ensure_state_of_systemd_service_file
