{% set app_dir = '/opt/{0}'.format(salt.pillar.get('django:app_name')) %}

build_static_assets_for_odlvideo:
  cmd.script:
    - name: {{ app_dir }}/webpack_if_prod.sh
    - env:
        - NODE_ENV: production
    - user: deploy

generate_deploy_hash_for_odlvideo:
  file.managed:
    - name: {{ app_dir }}/static/hash.txt
    - contents: {{ salt.git.rev_parse(app_dir, 'HEAD') }}
    - user: deploy

signal_odlvideo_deploy_complete:
  file.touch:
    - name: {{ app_dir }}/deploy_complete.txt
