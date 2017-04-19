{% set fd_limit = salt.pillar.get('fd_limit', 900000) %}
increase_file_descriptor_limit:
  cmd.run:
    - name: sysctl -w fs.file-max={{ fd_limit }}
  file.append:
    - name: /etc/sysctl.conf
    - text: fs.file_max={{ fd_limit }}
