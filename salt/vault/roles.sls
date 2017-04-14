{% set roles = salt.pillar.get('vault:roles') %}
{% for role_id, role in roles.items() %}
create_{{ role_id }}:
  vault.role_present:
    - name: {{ role.name }}
    - mount_point: {{ role.backend }}
    - options: {{ role.options }}
{% endfor %}
