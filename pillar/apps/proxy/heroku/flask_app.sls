{% set python_version = '3.7.1' %}
{% set python_bin_dir = '/usr/local/pyenv/versions/{0}/bin'.format(python_version) %}

django:
  user: flask
  group: flask
  pip_path: {{ python_bin_dir }}/pip3
  app_name: {{ app_name }}
  app_source:
    type: git
    repository_url: 'https://github.com/mitodl/salt-proxy/flask_app'
    state_params:
      - force_checkout: True
      - force_clone: True
  pkgs:
    - flask
  states:
    deploy:
      - apps.proxy.heroku.deploy
      - apps.proxy.flask.post_deploy
    config:
      - heroku.update_config
