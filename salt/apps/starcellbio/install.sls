{% set app_dir = '/opt/{0}'.format(salt.pillar.get('django:app_name')) %}

install_node_dependencies:
  npm.bootstrap:
    - name: {{ app_dir }}
