{% if salt.pillar.get('datadog_user') %}
ensure_vhost_access_for_datadog_user:
  rabbitmq_user.present:
    - name: {{ salt.pillar.get('datadog_user') }}
    - password: {{ salt.pillar.get('datadog_password') }}
    - tags:
        - monitoring
    - perms:
        {% for vhost in salt.rabbitmq.list_vhosts() %}
        - '{{ vhost }}':
            - '.*'
            - '.*'
            - '.*'
        {% endfor %}
{% endif %}
