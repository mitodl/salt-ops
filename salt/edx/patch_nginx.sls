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
