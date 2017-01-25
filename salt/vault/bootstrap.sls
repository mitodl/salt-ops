include:
  - vault.initialize

{% for backend in ['github', 'app-id', 'aws-ec2'] %}
enable_{{ backend }}_auth_backend:
  vault.auth_backend_enabled:
    - backend_type: {{ backend }}
    - require:
        - vault: initialize_vault_server
{% endfor %}

enable_syslog_audit_backend:
  vault.audit_backend_enabled:
    - backend_type: syslog

create_salt_master_policy:
  vault.policy_created:
    - name: salt-master
    - rules:
        path:
          '*':
            policy: sudo
          'sys/*':
            policy: sudo

register_root_ec2_role:
  vault.ec2_role_created:
    - role: salt-master
    - bound_iam_instance_profile_arn: {{ salt.grains.get('ec2:iam:info:instance_profile_arn') }}
    - bound_account_id: {{ salt.grains.get('ec2:account_id') }}
    - policies:
        - salt-master

authenticate_salt_master_to_vault:
  module.run:
    - name: vault.auth_ec2
    - kwargs:
        pkcs7: >-
          {{ salt.http.query('http://169.254.169.254/latest/dynamic/instance-identity/pkcs7')['body']|indent(10) }}
        role: salt-master
    - unless: {{ salt.vault.is_authenticated }}
