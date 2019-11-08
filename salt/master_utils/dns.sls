create_dns_entry_for_salt_master:
  boto_route53.present:
    - name: {{ salt.pillar.get('salt_master:dns', 'salt.odl.mit.edu') }}
    - value: {{ grains.get('ec2:public_ipv4') }}
    - record_type: A
    - zone: odl.mit.edu.
    - require:
        - module: load_contrib_modules

create_dns_private_entry_for_salt_master:
  boto_route53.present:
    - name: {{ salt.pillar.get('salt_master:private_dns', 'salt.private.odl.mit.edu') }}
    - value: {{ grains.get('fqdn') }}
    - record_type: CNAME
    - zone: private.odl.mit.edu.
