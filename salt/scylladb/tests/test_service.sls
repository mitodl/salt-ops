ensure_service_is_running:
  testinfra.service:
    - name: scylla
    - is_running: True
    - is_enabled: True

{% for portnum in [7000, 7001, 7199, 9042, 9100, 9160, 9180, 10000] %}
ensure_service_is_listening:
  testinfra.socket:
    - name: {{ salt.pillar.get('scylladb:configuration:listen_address') }}:{{ portnum }}
    - is_listening: True
{% endfor %}
