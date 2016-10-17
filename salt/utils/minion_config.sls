salt_minion_daemon_running:
  service.running:
    - name: salt-minion
    - enable: True

{% for fname, settings in salt.pillar.get('salt_minion:extra_configs', {}).items() %}
/etc/salt/minion.d/{{fname}}.conf:
  file.managed:
    - contents: |
        {{ settings | yaml(False) | indent(8) }}
    - watch_in:
        - service: salt_minion_daemon_running
    - makedirs: True
{% endfor %}
