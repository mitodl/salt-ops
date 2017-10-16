#!jinja|yaml

{% set lms_site_name = salt.pillar.get('edx:ansible_vars:EDXAPP_LMS_SITE_NAME') %}

add_etc_hosts_entry:
  host.present:
    - ip: 127.0.0.1
    - names:
      - {{ lms_site_name }}
