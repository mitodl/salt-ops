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

mongodb:
  overrides:
    version: '4.4'
    config:
      net:
        bindIp: '0.0.0.0,::'
        unixDomainSocket:
          enabled: False
        ipv6: True
    systemd_overrides:
      Service:
        PIDFile: '/run/mongodb/mongod.pid'
  admin_username: admin
  admin_password: __vault__::secret-{{ business_unit }}/{{ environment }}/mongodb-admin-password>data>value
  replset_name: rs0
  replset_config: {{ replset_config }}
  cluster_key: __vault__::secret-{{ business_unit }}/{{ environment }}/mongodb-cluster-key>data>value

{% if 'production' in environment %}
schedule:
  refresh_datadog_mongodb-{{ environment }}_credentials:
    days: 5
    function: state.sls
    args:
      - datadog.plugins
{% endif %}
