{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set purpose = salt.grains.get('purpose', 'current-residential-live') %}
{% set purpose_prefix = purpose.rsplit('-', 1)[0] %}
{% set purpose_suffix = purpose.replace('-', '_') %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}
{% set MYSQL_HOST = 'mysql.service.consul' %}
{% set MYSQL_PORT = 3306 %}
{% set cloudfront_domain = salt.sdb.get('sdb://consul/cloudfront/' ~ purpose_prefix ~ '-' ~ environment ~ '-cdn') %}

edx:
  ansible_vars:
    EDXAPP_EXTRA_MIDDLEWARE_CLASSES: [] # Worth keeping track of in case we need to take advantage of it
