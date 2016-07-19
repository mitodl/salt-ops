install_mit_github_ssh_key:
  file.managed:
    - name: /var/www/.ssh/id_rsa
    - user: www-data
    - group: www-data
    - contents_pillar: 'edx:gitreload:ssh_key'
    - makedirs: True
    - mode: 0600
    - dir_mode: 0700
