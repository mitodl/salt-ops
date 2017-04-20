{% set roles = salt.pillar.get('vault:roles') %}
{% for role_id, role in roles.items() %}
create_{{ role_id }}:
  vault.role_present:
    - name: {{ role.name }}
    - mount_point: {{ role.backend }}
    - override: {{ salt.pillar.get('vault:force_roles', False) }}
    - options:
        {% for key, value in role.options.items() %}
        {{ key }}: |
            {{ value }}
        {% endfor %}
{% endfor %}
