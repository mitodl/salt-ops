{% set app_dir = '/opt/{0}'.format(salt.pillar.get('django:app_name')) %}

install_node_dependencies:
  npm.bootstrap:
    - name: {{ app_dir }}
    - require:
        - git: deploy_application_source_to_destination
        - pkg: django_system_dependencies

download_jqdialog_dependency:
  file.managed:
    - name: {{ app_dir }}/html_app/js/jqdialog.js
    - source: https://raw.githubusercontent.com/knadh/jqdialog/f8dc7e4dca84ab132448723d3be35124d7de4fbc/jqdialog.js
    - source_hash: 2f12e880659e0b0092e3a5a7cf7f8bdbeb707b8b649a0a9cd5c263c7362c0b53
    - user: deploy
    - require:
        - git: deploy_application_source_to_destination

install_soyutils_dependency:
  file.copy:
    - name: {{ app_dir }}/html_app/js/soyutils.js
    - source: {{ app_dir }}/node_modules/closure-templates/soyutils.js
    - user: deploy
    - require:
        - npm: install_node_dependencies
