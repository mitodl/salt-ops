{% set app_dir = '/opt/{0}'.format(salt.pillar.get('django:app_name')) %}

build_static_assets_for_odlvideo:
  cmd.script:
    - name: {{ app_dir }}/webpack_if_prod.sh
    - cwd: {{ app_dir }}
    - env:
        - NODE_ENV: production
    - user: deploy

generate_deploy_hash_for_odlvideo:
  cmd.run:
    - name: 'git log --pretty=format:%H -n 1 > static/hash.txt'
    - cwd: {{ app_dir }}
    - user: deploy
