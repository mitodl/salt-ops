ensure_instance_profile_exists_for_mongodb:
  boto_iam_role.present:
    - name: mongodb-instance-role

deploy_logging_cloud_map:
  salt.function:
    - name: saltutil.runner
    - tgt: 'roles:master'
    - tgt_type: grain
    - arg:
        - cloud.map_run
    - kwarg:
        path: /etc/salt/cloud.maps.d/mongodb.yml
        parallel: True

{% for grains in salt.saltutil.runner(
    'mine.get',
    tgt='roles:mongodb', fun='grains.item', tgt_type='grain'
    ).items() %}
update_mongodb_instance:
  boto_ec2.instance_present:
    - vpc_name: 'Dogwood QA'
    - instance_id: {{ grains[1]['ec2:instance_id'] }}
    - instance_profile_name: mongodb
    - security_group_names: mongodb-dogwood_qa
    - target_state: running
{% endfor %}

resize_root_partitions_on_mongodb_nodes:
  salt.state:
    - tgt: 'G@roles:mongodb and G@environment:dogwood-qa'
    - tgt_type: compound
    - sls: utils.grow_partition

load_pillar_data_on_mongodb_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:mongodb and G@environment:dogwood-qa'
    - tgt_type: compound

populate_mine_with_mongodb_node_data:
  salt.function:
    - name: mine.update
    - tgt: 'G@roles:mongodb and G@environment:dogwood-qa'
    - tgt_type: compound

build_mongodb_nodes:
  salt.state:
    - tgt: 'G@roles:mongodb and G@environment:dogwood-qa'
    - tgt_type: compound
    - highstate: True

{% set hosts = [] %}
{% for host, grains in salt.saltutil.runner(
    'mine.get',
    tgt='G@roles:mongodb and G@environment:dogwood-qa', fun='grains.item', tgt_type='compound'
    ).items() %}
{% do hosts.append(grains['external_ip']) %}
{% endfor %}
