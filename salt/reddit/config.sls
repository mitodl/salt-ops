#!jinja|yaml

{% set reddit_config = salt.pillar.get('reddit:ini_config') %}
{% set reddit_dir = '/home/deploy/src/reddit/r2' %}

write_reddit_config:
  file.managed:
    - name: {{ reddit_dir }}/prod.update
    - source: salt://reddit/templates/conf.ini.jinja
    - template: jinja
    - context:
        settings: {{ reddit_config }}

update_reddit_config:
  cmd.run:
    - name: python updateini.py prod.update run.ini
    - cwd: {{ reddit_dir }}

restart_reddit_service:
  cmd.run:
    - name: reddit-restart
    - require:
        - cmd: update_reddit_config
