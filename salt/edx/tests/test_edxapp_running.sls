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
    'forum',
    'xqueue',
    'xqueue_consumer'
  ] %}

{% set socket_connections = {
    'ssl': 'tcp://0.0.0.0:443',
    'lms': 'tcp://0.0.0.0:8000',
    'gitreload_service': 'tcp://0.0.0.0:8095',
    'xqueue': 'tcp://0.0.0.0:18040',
    'forum': 'tcp://0.0.0.0:4567',
    'rabbitmq': 'tcp://rabbitmq.service.consul:15672',
    'elasticsearch': 'tcp://elasticsearch.service.consul:9200',
    'mysql':'tcp://mysql.service.consul:3306',
    'mongodb': 'tcp://mongodb-master.service.consul:27017',
  } %}

{% set running_services = [
    'nginx',
    'fluentd',
    'supervisor',
    'gitreload'
  ] %}

{% set lms_env = {
  'mitx_email': salt.pillar.get('edx:ansible_vars:edxapp_generic_env_config:DEFAULT_FROM_EMAIL'),
  'mitx_theme': salt.pillar.get('edx:ansible_vars:edxapp_generic_env_config:THEME_NAME'),
  'rabbitmq_service': salt.pillar.get('edx:ansible_vars:xqueue_env_config:RABBIT_HOST')
  } %}

{% for sv_service in supervisor_services %}
test_edxapp_supervisor_{{ sv_service }}:
  testinfra.supervisor:
    - name: {{ sv_service }}
    - is_running: True
{% endfor %}

{% for connection in socket_connections %}
test_edxapp_{{ connection }}:
  testinfra.socket_host:
    - name: {{ connection }}
    - is_listening: True
{% endfor %}

{% for service in running_services %}
test_edxapp_{{ service }}:
  testinfra.service:
    - name: {{ service }}
    - is_running: True
{% endfor %}

test_edxapp_cms:
  testinfra.supervisor:
      - name: 'edxapp:cms'
      - is_running: True

# Check if AWS EFS is mounted
test_edxapp_efs_mount:
  testinfra.mount_point:
    - name: '/mnt/data'
    - exists: True
    - filesystem:
        expected: nfs4
        comparison: eq

{% for attribute, value in lms_env.items() %}
test_edxapp_lms_env_{{ value }}:
  testinfra.file:
    - name: '/edx/app/edxapp/lms.env.json'
    - exists: True
    - contains:
        parameter: {{ value }}
        expected: True
        comparison: is_
{% endfor %}