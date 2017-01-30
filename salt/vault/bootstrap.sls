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
  vault.ec2_minion_authenticated:
    - role: salt-master
    - is_master: True

restart_minion_after_auth:
  service.running:
    - name: salt-minion
    - watch:
        - vault: authenticate_salt_master_to_vault

restart_master_after_auth:
  service.running:
    - name: salt-master
    - watch:
        - vault: authenticate_salt_master_to_vault
