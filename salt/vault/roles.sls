{% set roles = salt.pillar.get('vault:roles') %}
{% for role_id, role in roles.items() %}
{% for environment in role.environments %}
{% set env_data = salt.pillar.get('environments:{}'.format(environment), {}) %}
  {% for purpose in env_data.purposes %}
create_{{ role.name }}_role_in_{{ role.backend }}_for_{{ purpose }}_in_{{ environment }}:
  vault.role_present:
    - name: {{ role.name }}-{{ purpose }}
    - mount_point: {{ role.backend }}-{{ environment }}
    - options:
        {% for key, value in role.options.items() %}
        {% if key == role.get('formatted_option', '') %}
        {{ key }}: |
            {{ value|replace('%purpose%', purpose.replace('-', '_')) }}
        {% else %}
        {{ key }}: |
            {{ value }}
        {% endif %}
        {% endfor %}
  {% endfor %}
{% endfor %}
{% endfor %}
