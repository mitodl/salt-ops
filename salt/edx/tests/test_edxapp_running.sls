#!jinja|yaml

{# Test to verify that the edxapp is funcitional and configured with some of
our configurations. Test the following:
- edxapp supervisor services are running
- edxapp instance can reach select services
- services that edxapp relies on locally
- edxapp:cms service is only running on edx-draft
- AWS EBS data repo is mounted
- spot check custom vars are in lms.{env|auth} #}


{% set supervisor_services = [
    'edxapp:lms',
    'xqueue',
    'xqueue_consumer'
  ] %}

{% set socket_connections = {
    'ssl': 'tcp://0.0.0.0:443',
    'lms': 'tcp://127.0.0.1:8000',
    'xqueue': 'tcp://0.0.0.0:18040',
  } %}

# Additional connections that should be tested in integration tests: (TMM 2017/07/31)
# 'rabbitmq': 'tcp://rabbitmq.service.consul:15672',
# 'elasticsearch': 'tcp://elasticsearch.service.consul:9200',
# 'mysql':'tcp://mysql.service.consul:3306',
# 'mongodb': 'tcp://mongodb-master.service.consul:27017',

{% set running_services = [
    'nginx',
    'supervisor'
  ] %}

{% set lms_env = {
  'mitx_email': salt.pillar.get('edx:ansible_vars:EDXAPP_DEFAULT_FROM_EMAIL'),
  'mitx_theme': salt.pillar.get('edx:ansible_vars:EDXAPP_DEFAULT_SITE_THEME'),
  'rabbitmq_service': salt.pillar.get('edx:ansible_vars:EDXAPP_RABBIT_HOSTNAME')
  } %}

# {% for sv_service in supervisor_services %}
# test_edxapp_supervisor_{{ sv_service }}:
#   testinfra.supervisor:
#     - name: {{ sv_service }}
#     - is_running: True
# {% endfor %}

{% for service in running_services %}
test_edxapp_{{ service }}:
  testinfra.service:
    - name: {{ service }}
    - is_running: True
{% endfor %}

{% if not ('sandbox' in salt.grains.get('roles')) %}
# Check if AWS EFS is mounted
test_edxapp_efs_mount:
  testinfra.mount_point:
    - name: '/mnt/data'
    - exists: True
    - filesystem:
        expected: nfs4
        comparison: eq
{% endif %}

{% for attribute, value in lms_env.items() %}
test_edxapp_lms_env_{{ attribute }}:
  testinfra.file:
    - name: '/edx/etc/lms.yml'
    - exists: True
    - content_string:
        expected: '{{ value }}'
        comparison: search
{% endfor %}

{% for connection, value in socket_connections.items() %}
test_edxapp_{{ connection }}:
  testinfra.socket:
    - name: {{ value }}
    - is_listening: True
{% endfor %}

# add_an_artificial_wait_for_forum:
#   module.run:
#     - name: test.sleep
#     - length: 30
#     - require_in:
#         - testinfra: test_edxapp_forum
