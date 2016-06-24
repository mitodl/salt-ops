# Add stub_status on parameter to nginx configuration to enable
# tracking of operational stats

{% set nginx_config_file = salt.command.run('nginx -t') %}

add_stub_status_configuration_to_nginx:
  file.managed:
    - name: 
        
