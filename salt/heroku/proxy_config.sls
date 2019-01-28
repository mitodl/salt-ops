configure_heroku_proxy:
  salt_proxy.configure_proxy:
    - proxyname: heroku_proxy
    - start: True
