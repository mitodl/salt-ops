{% set fd_limit = salt.pillar.get('fd_limit', 900000) %}
increase_file_descriptor_limit:
  cmd.run:
    - name: sysctl -w fs.file-max={{ fd_limit }}
  file.replace:
    - name: /etc/sysctl.conf
    # Look for underscore or hyphen because underscore has been used before on
    # some of our systems. Hyphen is the correct one. (Per `/sbin/sysctl -a')
    - pattern: fs.file[\-_]max=\d+
    - repl: fs.file-max={{ fd_limit }}
    - append_if_not_found: True
