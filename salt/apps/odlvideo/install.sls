ensure_yarn_is_installed_for_odlvideo:
  npm.installed:
    - name: 'yarn@1.22.4'
    - user: root

install_node_dependencies:
  cmd.run:
    - name: yarn install
    - cwd: /opt/{{ salt.pillar.get('django:app_name') }}
    - require:
        - deploy_application_source_to_destination
