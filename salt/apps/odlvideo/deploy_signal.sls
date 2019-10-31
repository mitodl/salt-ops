{% set app_dir = '/opt/{0}'.format(salt.pillar.get('django:app_name')) %}

signal_odlvideo_deploy_complete:
  file.touch:
    - name: {{ app_dir }}/deploy_complete.txt
    - order: last
