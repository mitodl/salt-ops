{% for env in ['ci', 'rc', 'prod'] %}
{% for app in ['bootcamp-ecommerce', 'micromasters', 'odl-open-discussions', 'odl-video'] %}
configure_heroku_proxy_for_{{ app }}-{{ env }}:
  salt_proxy.configure_proxy:
    - proxyname: {{ app }}-{{ env }}
    - start: True
{% endfor %}
{% endfor %}
