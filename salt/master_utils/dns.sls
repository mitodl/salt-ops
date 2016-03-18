include:
  - master.aws
  - master_utils.contrib

create_dns_entry_for_salt_master:
  boto_route53.present:
    - name: {{ salt.pillar.get('salt_master:dns', 'salt.odl.mit.edu') }}
    - value: {{ grains.get('external_ip') }}
    - record_type: A
    - zone: odl.mit.edu.
    - require:
        - pip: install_aws_python_dependencies
        - module: load_contrib_modules

create_dns_private_entry_for_salt_master:
  boto_route53.present:
    - name: {{ salt.pillar.get('salt_master:dns', 'salt.private.odl.mit.edu') }}
    - value: {{ grains.get('ec2:local_hostname') }}
    - record_type: CNAME
    - zone: private.odl.mit.edu.
    - require:
        - pip: install_aws_python_dependencies
        - module: load_contrib_modules
