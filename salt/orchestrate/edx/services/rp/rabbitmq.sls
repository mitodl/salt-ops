{% set subnet_ids = [] %}
{% for subnet in salt.boto_vpc.describe_subnets(subnet_names=[
    'public1-mitx-rp', 'public2-mitx-rp', 'public3-mitx-rp'])['subnets'] %}
{% do subnet_ids.append('{0}'.format(subnet['id'])) %}
{% endfor %}
load_rabbitmq_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/rabbitmq.conf
    - source: salt://orchestrate/aws/cloud_profiles/rabbitmq.conf

generate_rabbitmq_cloud_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/mitx_rp_rabbitmq_map.yml
    - source: salt://orchestrate/aws/map_templates/rabbitmq.yml
    - template: jinja
    - makedirs: True
    - context:
        environment_name: mitx-rp
        roles:
          - rabbitmq
        securitygroupid:
          - {{ salt.boto_secgroup.get_group_id(
            'rabbitmq-mitx-rp', vpc_name='MITx RP') }}
          - {{ salt.boto_secgroup.get_group_id(
            'salt_master-mitx-rp', vpc_name='MITx RP') }}
        subnetids: {{ subnet_ids }}

ensure_instance_profile_exists_for_rabbitmq:
  boto_iam_role.present:
    - name: rabbitmq-instance-role

deploy_rabbitmq_cloud_map:
  salt.function:
    - name: saltutil.runner
    - tgt: 'roles:master'
    - tgt_type: grain
    - arg:
        - cloud.map_run
    - kwarg:
        path: /etc/salt/cloud.maps.d/mitx_rp_rabbitmq_map.yml
        parallel: True
    - require:
        - file: generate_rabbitmq_cloud_map_file

load_pillar_data_on_rabbitmq_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:rabbitmq and G@environment:mitx-rp'
    - tgt_type: compound
    - require:
        - salt: deploy_rabbitmq_cloud_map

populate_mine_with_rabbitmq_node_data:
  salt.function:
    - name: mine.update
    - tgt: 'G@roles:rabbitmq and G@environment:mitx-rp'
    - tgt_type: compound
    - require:
        - salt: load_pillar_data_on_rabbitmq_nodes

build_rabbitmq_nodes:
  salt.state:
    - tgt: 'G@roles:rabbitmq and G@environment:mitx-rp'
    - tgt_type: compound
    - highstate: True
    - require:
        - salt: populate_mine_with_rabbitmq_node_data
