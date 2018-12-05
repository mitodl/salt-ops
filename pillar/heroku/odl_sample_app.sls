flask:
  address: amps.odl.mit.edu
  port: 8000

proxy:
  proxytype: rest_sample
  url: https://{{ flask.address }}:{{ flask.port }}

heroku:
  app_name: 'odl-sample-app'
  config_vars:
    a: 44
    b: 55
