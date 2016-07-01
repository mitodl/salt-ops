{% set subnet_ids = [] %}
{% for subnet in salt.boto_vpc.describe_subnets(subnet_names=[
    'public1-dogwood_qa', 'public2-dogwood_qa', 'public3-dogwood_qa']) %}
{% do subnet_ids.append(subnet['id']) %}
{% endfor %}
generate_cloud_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/dogwood_qa_edx_map.yml
    - source: salt://orchestrate/aws/map_templates/edx.yml
    - template: jinja
    - makedirs: True
    - context:
        environment_name: dogwood-qa
        roles:
          - edx
        securitygroupid: {{ salt.boto_secgroup.get_group_id(
            'edx-dogwood_qa', vpc_name='Dogwood QA') }}
        subnetids: {{ subnet_ids }}

ensure_instance_profile_exists_for_edx:
  boto_iam_role.present:
    - name: edx-instance-role

deploy_logging_cloud_map:
  salt.function:
    - name: saltutil.runner
    - tgt: 'roles:master'
    - tgt_type: grain
    - arg:
        - cloud.map_run
    - kwarg:
        path: /etc/salt/cloud.maps.d/dogwood_qa_edx_map.yml
        parallel: True
    - require:
        - file: generate_cloud_map_file

{% for grains in salt.saltutil.runner(
    'mine.get',
    tgt='roles:edx', fun='grains.item', tgt_type='grain'
    ).items() %}
update_edx_instance:
  boto_ec2.instance_present:
    - vpc_name: 'Dogwood QA'
    - instance_id: {{ grains[1]['ec2:instance_id'] }}
    - instance_profile_name: edx
    - security_group_names: edx-dogwood_qa
    - target_state: running
{% endfor %}

resize_root_partitions_on_edx_nodes:
  salt.state:
    - tgt: 'G@roles:edx and G@environment:dogwood-qa'
    - tgt_type: compound
    - sls: utils.grow_partition
    - require:
        - salt: deploy_edx_cloud_map

load_pillar_data_on_edx_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:edx and G@environment:dogwood-qa'
    - tgt_type: compound
    - require:
        - salt: deploy_edx_cloud_map

populate_mine_with_edx_node_data:
  salt.function:
    - name: mine.update
    - tgt: 'G@roles:edx and G@environment:dogwood-qa'
    - tgt_type: compound
    - require:
        - salt: load_pillar_data_on_edx_nodes

{# Reload the pillar data to update values from the salt mine #}
reload_pillar_data_on_edx_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:edx and G@environment:dogwood_qa'
    - tgt_type: compound
    - require:
        - salt: populate_mine_with_edx_data

build_edx_nodes:
  salt.state:
    - tgt: 'G@roles:edx and G@environment:dogwood-qa'
    - tgt_type: compound
    - highstate: True
    - require:
        - salt: reload_pillar_data_on_edx_nodes
