install_debian_package_dependencies:
  pkg.installed:
    - pkgs:
        - alien
        - unixodbc
        - unixodbc-dev

install_dremio_odbc_driver:
  file.managed:
    - name: /tmp/dremio-odbc.rpm
    - source: http://download.dremio.com/odbc-driver/dremio-odbc-LATEST.x86_64.rpm
    - skip_verify: True
  cmd.run:
    - name: alien -i --scripts /tmp/dremio-odbc.rpm
    - require:
        - file: install_dremio_odbc_driver

install_python_dependencies:
  pip.installed:
    - pkgs:
        - pyodbc
        - pandas
    - bin_env: {{ salt.pillar.get('django:pip_path') }}
    - require:
        - pkg: install_debian_package_dependencies

{% for name, fname, target in [
('pyfile', 'dremio_odbc.py', 'redash/query_runner/dremio_odbc.py'),
('dist_logo', 'dremio_odbc.png', 'client/dist/images/db-logos/dremio_odbc.png'),
('asset_logo', 'dremio_odbc.png', 'client/app/assets/images/db-logos/dremio_odbc.png')] %}
download_dremio_datasource_{{ name }}:
  file.managed:
    - name: /opt/redash/{{ target }}
    - source: https://raw.githubusercontent.com/mitodl/DremioDSforRedash/master/{{ fname }}
    - user: redash
    - group: redash
    - skip_verify: True
{% endfor %}
