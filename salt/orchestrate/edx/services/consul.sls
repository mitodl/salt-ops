{% set subnet_ids = [] %}
{% for subnet in salt.boto_vpc.describe_subnets(subnet_names=[
    'public1-mitx-qa', 'public2-mitx-qa', 'public3-mitx-qa'])['subnets'] %}
{% do subnet_ids.append('{0}'.format(subnet['id'])) %}
{% endfor %}
{% set VPC_NAME = 'MITx QA' %}

load_consul_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/consul.conf
    - source: salt://orchestrate/aws/cloud_profiles/consul.conf

generate_cloud_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/mitx_qa_consul_map.yml
    - source: salt://orchestrate/aws/map_templates/consul.yml
    - template: jinja
    - makedirs: True
    - context:
        environment_name: mitx-qa
        roles:
          - consul_server
          - service_discovery
        securitygroupid:
          - {{ salt.boto_secgroup.get_group_id(
            'consul-mitx-qa', vpc_name=VPC_NAME) }}
          - {{ salt.boto_secgroup.get_group_id(
            'salt_master-mitx-qa', vpc_name=VPC_NAME) }}
        subnetids: {{ subnet_ids }}
    - require:
        - file: load_consul_cloud_profile

deploy_consul_nodes:
  salt.function:
    - name: saltutil.runner
    - tgt: 'roles:master'
    - tgt_type: grain
    - arg:
        - cloud.map_run
    - kwarg:
        path: /etc/salt/cloud.maps.d/mitx_qa_consul_map.yml
        parallel: True
    - require:
        - file: generate_cloud_map_file

load_pillar_data_on_mitx_consul_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:consul_server and G@environment:mitx-qa'
    - tgt_type: compound
    - require:
        - salt: deploy_consul_nodes

populate_mine_with_mitx_consul_data:
  salt.function:
    - name: mine.update
    - tgt: 'G@roles:consul_server and G@environment:mitx-qa'
    - tgt_type: compound
    - require:
        - salt: load_pillar_data_on_mitx_consul_nodes

{# Reload the pillar data to update values from the salt mine #}
reload_pillar_data_on_mitx_consul_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:consul_server and G@environment:mitx-qa'
    - tgt_type: compound
    - require:
        - salt: populate_mine_with_mitx_consul_data

install_git_on_consul_nodes_for_cloning_forked_python_packages:
  salt.function:
    - name: pkg.install
    - tgt: 'G@roles:consul_server and G@environment:mitx-qa'
    - tgt_type: compound
    - arg:
        - git

build_mitx_consul_nodes:
  salt.state:
    - tgt: 'G@roles:consul_server and G@environment:mitx-qa'
    - tgt_type: compound
    - highstate: True
    - require:
        - salt: reload_pillar_data_on_mitx_consul_nodes
