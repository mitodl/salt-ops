{% set app_name = 'odl-video-service' %}
{% set env_settings = salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml", dest=None)|load_yaml %}
{% set ENVIRONMENT = salt.grains.get('environment', 'rc-apps') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set server_domain_names = env_data.purposes['odl-video-service'].domains %}
{% set ovs_login_path = 'login' %}

nginx:
  install_from_source: True
  source_version: 1.13.8
  source_hash: 8410b6c31ff59a763abf7e5a5316e7629f5a5033c95a3a0ebde727f9ec8464c5
  certificates:
    ovs_web_cert:
      public_cert: __vault__::secret-odl-video/{{ ENVIRONMENT }}/ovs_web_cert>data>value
      private_key: __vault__::secret-odl-video/{{ ENVIRONMENT }}/ovs_web_cert>data>key
  server:
    extra_config:
      shib_params:
        source_path: salt://nginx/files/default/nginx.conf
        shib_request_set:
          - $shib_remote_user $upstream_http_variable_remote_user
          - $shib_eppn $upstream_http_variable_eppn
          - $shib_mail $upstream_http_variable_mail
          - $shib_displayname $upstream_http_variable_displayname
        uwsgi_param:
          - REMOTE_USER $shib_remote_user
          - EPPN $shib_eppn
          - MAIL $shib_mail
          - DISPLAY_NAME $shib_displayname
  servers:
    managed:
      {{ app_name }}:
        enabled: True
        config:
          - server:
              - server_name: {{ server_domain_names|tojson }}
              - listen: 80
              - listen: '[::]:80'
              - location /:
                  - return: 301 https://$host$request_uri
          - server:
              - server_name: {{ server_domain_names|tojson }}
              - listen: '443 ssl default_server'
              - listen: '[::]:443 ssl'
              - root: /opt/odl-video-service/
              - ssl_certificate: /etc/nginx/ssl/ovs_web_cert.crt
              - ssl_certificate_key: /etc/nginx/ssl/ovs_web_cert.key
              - ssl_stapling: 'on'
              - ssl_stapling_verify: 'on'
              - ssl_session_timeout: 1d
              - ssl_session_tickets: 'off'
              - ssl_protocols: 'TLSv1 TLSv1.1 TLSv1.2 TLSv1.3'
              - ssl_ciphers: "TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256\
                  :DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384\
                  :ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256\
                  :ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256"
              - ssl_prefer_server_ciphers: 'on'
              - resolver: 1.1.1.1
              - location /shibauthorizer:
                  - internal: ''
                  - include: fastcgi_params
                  - include: includes/shib_fastcgi_params
                  - fastcgi_pass: 'unix:/run/shibauthorizer.sock'
              - location /Shibboleth.sso:
                  - include: fastcgi_params
                  - include: includes/shib_fastcgi_params
                  - fastcgi_pass: 'unix:/run/shibresponder.sock'
              - location /{{ ovs_login_path }}:
                  - include: includes/shib_clear_headers
                  - shib_request: /shibauthorizer
                  - shib_request_use_headers: 'on'
                  - include: conf.d/shib_params.conf
                  - include: uwsgi_params
                  - uwsgi_ignore_client_abort: 'on'
                  - uwsgi_pass: unix:/var/run/uwsgi/odl-video-service.sock
              - location /status:
                  - include: uwsgi_params
                  - uwsgi_pass: unix:/var/run/uwsgi/odl-video-service.sock
              - location /:
                  - include: uwsgi_params
                  - uwsgi_ignore_client_abort: 'on'
                  - uwsgi_pass: unix:/var/run/uwsgi/odl-video-service.sock
              - location ~* /static/(.*$):
                  - expires: max
                  - add_header: 'Access-Control-Allow-Origin *'
                  - try_files: '$uri $uri/ /staticfiles/$1 /staticfiles/$1/ =404'
              - location /collections/letterlocking:
                  - return: 301 https://www.youtube.com/c/Letterlocking/videos
              - location /collections/letterlocking/videos:
                  - return: 301 https://www.youtube.com/c/Letterlocking/videos
              - location /collections/letterlocking/videos/30213-iron-gall-ink-a-quick-and-easy-method:
                  - return: 301 https://www.youtube.com/playlist?list=PL2uZTM-xaHP4tFQT7eTTK3sWRoJMcDWwB
              - location /collections/letterlocking/videos/30215-elizabeth-stuart-s-deciphering-sir-thomas-roe-s-letter-cryptography-1626:
                  - return: 301 https://www.youtube.com/watch?v=6X_ZXrLs8I8&list=PL2uZTM-xaHP4tFQT7eTTK3sWRoJMcDWwB&index=3&t=0s
              - location /collections/letterlocking/videos/30209-a-tiny-spy-letter-constantijn-huygens-to-amalia-von-solms-1635:
                  - return: 301 https://www.youtube.com/watch?v=PePWd-h679c&list=PL2uZTM-xaHP4tFQT7eTTK3sWRoJMcDWwB&index=7&t=0s
              - location /collections/c8c5179c7596408fa0f09f6b76082331:
                  - return: 301 https://www.youtube.com/c/MITEnergyInitiative
