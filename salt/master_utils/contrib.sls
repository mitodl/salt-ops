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
    - require:
        - git: install_contrib_modules

load_contrib_modules:
  module.run:
    - name: saltutil.sync_all
    - refresh: True
    - require:
        - cmd: install_contrib_modules
