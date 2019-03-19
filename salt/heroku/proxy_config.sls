{% for env in ['ci', 'rc', 'prod'] %}
{% for app in ['bootcamp-ecommerce', 'micromasters', 'odl-open-discussions', 'xpro'] %}
configure_heroku_proxy_for_{{ app }}-{{ env }}:
  salt_proxy.configure_proxy:
    - proxyname: proxy-{{ app }}-{{ env }}
    - start: True
{% endfor %}
{% endfor %}

configure_heroku_proxy_for_odl-video-ci:
  salt_proxy.configure_proxy:
    - proxyname: proxy-odl-video-ci
    - start: True
