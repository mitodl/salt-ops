{% set subnet_ids = [] %}
{% for subnet in salt.boto_vpc.describe_subnets(subnet_names=[
    'public1-operations', 'public2-operations', 'public3-operations'])['subnets'] %}
{% do subnet_ids.append('{0}'.format(subnet['id'])) %}
{% endfor %}

generate_cloud_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/operations_consul_map.yml
    - source: salt://orchestrate/aws/map_templates/consul.yml
    - template: jinja
    - makedirs: True
    - context:
        environment_name: operations
        roles:
          - consul_server
          - service_discovery
          - vault_server
        securitygroupid:
          - {{ salt.boto_secgroup.get_group_id(
            'consul-operations', vpc_name='mitodl-operations-services') }}
          - {{ salt.boto_secgroup.get_group_id(
            'default', vpc_name='mitodl-operations-services') }}
        subnetids: {{ subnet_ids }}

deploy_consul_nodes:
  salt.function:
    - name: saltutil.runner
    - tgt: 'roles:master'
    - tgt_type: grain
    - arg:
        - cloud.map_run
    - kwarg:
        path: /etc/salt/cloud.maps.d/operations_consul_map.yml
        parallel: True
    - require:
        - file: generate_cloud_map_file

load_pillar_data_on_operations_consul_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:consul_server and G@environment:operations'
    - tgt_type: compound
    - require:
        - salt: deploy_consul_nodes

populate_mine_with_operations_consul_data:
  salt.function:
    - name: mine.update
    - tgt: 'G@roles:consul_server and G@environment:operations'
    - tgt_type: compound
    - require:
        - salt: load_pillar_data_on_operations_consul_nodes

{# Reload the pillar data to update values from the salt mine #}
reload_pillar_data_on_operations_consul_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:consul_server and G@environment:operations'
    - tgt_type: compound
    - require:
        - salt: populate_mine_with_operations_consul_data

install_git_on_consul_nodes_for_cloning_forked_python_packages:
  salt.function:
    - name: pkg.install
    - tgt: 'G@roles:consul_server and G@environment:operations'
    - tgt_type: compound
    - arg:
        - git

build_operations_consul_nodes:
  salt.state:
    - tgt: 'G@roles:consul_server and G@environment:operations'
    - tgt_type: compound
    - highstate: True
    - require:
        - salt: reload_pillar_data_on_operations_consul_nodes

bootstrap_vault_nodes:
  salt.state:
    - tgt: consul-operations-0
    - sls:
        - vault.bootstrap
    - pillar:
        vault.verify: False
