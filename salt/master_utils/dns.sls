include:
  - master.aws

create_dns_entry_for_salt_master:
  boto_route53.present:
    - name: {{ salt.pillar.get('salt_master:dns', 'salt.mitx.mit.edu') }}
    - value: {{ salt.cmd.run('curl http://169.254.169.254/latest/meta-data/public-ipv4') }}
    - record_type: A
    - zone: mitx.mit.edu.
    - require:
        - pip: install_aws_python_dependencies
