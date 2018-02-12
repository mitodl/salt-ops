#!jinja|yaml|gpg
{% set business_unit = salt.grains.get('business_unit') %}
{% set environment = salt.grains.get('environment') %}
{% set replset_config = {'_id': salt.pillar.get('mongodb:replset_name', 'rs0'), 'members': []} %}
{% set member_id = 0 %}
{% set eth0_index = 0 %}
{% set member_addrs = salt.saltutil.runner('mine.get', tgt='G@roles:mongodb and G@environment:{0}'.format(environment), fun='network.ip_addrs', tgt_type='compound') %}
{% for id, addrs in member_addrs.items() %}
{% set member_id = id[-1]|int %}
{% do replset_config['members'].append({'_id': member_id, 'host': addrs[eth0_index] }) %}
{% endfor %}

mine_functions:
  network.ip_addrs: [eth0]
  network.get_hostname: []

mongodb:
  overrides:
    install_pkgrepo: False
    pkgs:
      - mongodb
    service_name: mongodb
  admin_username: admin
  admin_password: {{ salt.vault.read('secret-{}/{}/mongodb-admin-password'.format(business_unit, environment)).data.value }}
  replset_name: rs0
  replset_config: {{ replset_config }}
  cluster_key: {{ salt.vault.read('secret-{}/{}/mongodb-cluster-key'.format(business_unit, environment)).data.value }}
