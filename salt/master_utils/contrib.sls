include:
  - master

install_contrib_modules:
  git.latest:
    - name: https://github.com/saltstack/salt-contrib.git
    - target: /etc/salt/contrib
  cmd.run:
    - name: /etc/salt/contrib/link_contrib.py /srv/salt
    - unless: ls /srv/salt/_grains/ec2_info.py
    - watch_in:
        - service: salt_minion_running
        - service: salt_master_running
