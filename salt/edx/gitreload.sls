install_mit_github_ssh_key:
  file.managed:
    - name: /var/www/.ssh/id_rsa
    - user: www-data
    - group: www-data
    - contents_pillar: 'edx:gitreload:ssh_key'
    - makedirs: True
    - mode: 0600
    - dir_mode: 0700

create_empty_known_hosts:
  file.managed:
    - name: /var/www/.ssh/known_hosts
    - user: www-data
    - group: www-data
    - contents:
    - require:
      - file: install_mit_github_ssh_key

{% for item in salt.pillar.get('edx:gitreload:ssh_hosts') %}
grab_{{ item }}_ssh_host_key:
  cmd.run:
    - name: ssh-keyscan {{ item }} >> /var/www/.ssh/known_hosts
    - runas: www-data
    - require:
      - file: create_empty_known_hosts
{% endfor %}
