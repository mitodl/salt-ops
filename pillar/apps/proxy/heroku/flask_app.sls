{% set python_version = '3.7.1' %}
{% set python_bin_dir = '/usr/local/pyenv/versions/{0}/bin'.format(python_version) %}

proxy:
  proxytype: rest_sample
  url: https://amps.odl.mit.edu:8000

django:
  user: flask
  group: flask
  pip_path: {{ python_bin_dir }}/pip3
  app_name: {{ app_name }}
  app_source:
    type: git
    repository_url: 'https://github.com/mitodl/salt-proxy/flask_app'
    state_params:
      - overwrite: True
      - enforce_toplevel: False
  pkgs:
    - flask
  states:
    deploy:
      - apps.proxy.heroku.deploy
      - apps.proxy.flask.post_deploy
    config:
      - heroku.update_config
