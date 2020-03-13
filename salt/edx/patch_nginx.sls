update_max_upload_size_for_lms:
  file.replace:
    - name: /etc/nginx/sites-enabled/lms
    - pattern: 'client_max_body_size\s+\d+M;'
    - repl: 'client_max_body_size {{ salt.pillar.get("edx:edxapp:max_upload_size", "20") }}M;'
    - backup: False
  service.running:
    - name: nginx
    - reload: True

configure_nginx_status_module_for_edx:
  file.managed:
    - name: /etc/nginx/sites-enabled/status_monitor
    - contents: |
        server {
            listen 127.0.0.1:80;
            location /nginx_status {
                stub_status on;
                access_log off;
                allow 127.0.0.1;
                deny all;
            }
        }
    - group: www-data

reload_edx_nginx_service_after_updates:
  service.running:
    - name: nginx
    - reload: True
    - onchanges_any:
        - file: configure_nginx_status_module_for_edx
        - file: update_max_upload_size_for_lms
