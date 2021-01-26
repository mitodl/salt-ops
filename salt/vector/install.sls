install_vector_repo:
  cmd.run:
    - name: curl -1sLf 'https://repositories.timber.io/public/vector/cfg/setup/bash.deb.sh' | bash

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
