{% from "django/map.jinja" import django with context %}
{% set ssh_hosts = salt.pillar.get('edx:ssh_hosts',
   [{'name': 'github.com', 'fingerprint': '9d:38:5b:83:a9:17:52:92:56:1a:5e:c4:d4:81:8e:0a:ca:51:a2:64:f1:74:20:11:2e:f8:8a:c3:a1:39:49:8f'},
    {'name': 'github.mit.edu', 'fingerprint': 'aa:d2:e9:66:7e:46:77:d3:7d:d9:39:3f:f4:9f:17:a1:18:c1:87:8f:69:cb:8f:d0:db:10:b7:71:5e:ad:57:68'}]) %}

add_deploy_key_for_cas_repo:
  file.managed:
    - name: {{ salt.pillar.get('django:app_source:identity') }}
    - contents_pillar: mitx_cas:deploy_key
    - user: {{ django.user }}
    - mode: 0600
    - makedirs: True
    - require:
        - user: create_django_app_user
    - require_in:
        - git: deploy_application_source_to_destination

{% for host in ssh_hosts %}
add_{{ host.name }}_to_known_hosts_for_mitx_cas:
  ssh_known_hosts.present:
    - name: {{ host.name }}
    - user: {{ django.user }}
    - enc: ssh-rsa
    - fingerprint: {{ host.fingerprint }}
    - fingerprint_hash_type: sha256
    - require:
      - file: add_deploy_key_for_cas_repo
    - require_in:
        - git: deploy_application_source_to_destination
{% endfor %}
