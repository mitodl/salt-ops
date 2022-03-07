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

{% set vector_service = salt.grains.filter_by({
    'systemd': {
      'destination_path': '/etc/systemd/system/vector.service',
      'source_path': 'salt://vector/files/vector.service',
    },
    'upstart': {
      'destination_path': '/etc/init/vector.conf',
      'source_path': 'salt://vector/files/vector.conf',
    }
  }, grain='init')
%}

ensure_state_of_systemd_service_file:
  file.managed:
    - name: {{ vector_service.destination_path }}
    - source: {{ vector_service.source_path }}
  {% if salt.grains.get('init') == 'systemd' %}
  cmd.wait:
    - name: systemctl daemon-reload
    - onchanges:
        - file: ensure_state_of_systemd_service_file
  {% endif %}
