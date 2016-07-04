{% set subnet_ids = [] %}
{% for subnet in salt.boto_vpc.describe_subnets(subnet_names=[
    'public1-dogwood_qa', 'public2-dogwood_qa', 'public3-dogwood_qa'])['subnets'] %}
{% do subnet_ids.append('{0}'.format(subnet['id'])) %}
{% endfor %}
load_mongodb_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/mongodb.conf
    - source: salt://orchestrate/aws/cloud_profiles/mongodb.conf

generate_mongodb_cloud_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/dogwood_qa_mongodb_map.yml
    - source: salt://orchestrate/aws/map_templates/mongodb.yml
    - template: jinja
    - makedirs: True
    - context:
        environment_name: dogwood-qa
        roles:
          - mongodb
        securitygroupid:
          - {{ salt.boto_secgroup.get_group_id(
            'mongodb-dogwood_qa', vpc_name='Dogwood QA') }}
          - {{ salt.boto_secgroup.get_group_id(
            'salt_master-dogwood_qa', vpc_name='Dogwood QA') }}
        subnetids: {{ subnet_ids }}
    - require:
        - file: load_mongodb_cloud_profile

ensure_instance_profile_exists_for_mongodb:
  boto_iam_role.present:
    - name: mongodb-instance-role

deploy_mongodb_cloud_map:
  salt.function:
    - name: saltutil.runner
    - tgt: 'roles:master'
    - tgt_type: grain
    - arg:
        - cloud.map_run
    - kwarg:
        path: /etc/salt/cloud.maps.d/dogwood_qa_mongodb_map.yml
        parallel: True
    - require:
        - file: generate_mongodb_cloud_map_file

load_pillar_data_on_dogwood_mongodb_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:mongodb and G@environment:dogwood-qa'
    - tgt_type: compound

populate_mine_with_mongodb_node_data:
  salt.function:
    - name: mine.update
    - tgt: 'G@roles:mongodb and G@environment:dogwood-qa'
    - tgt_type: compound
    - require:
        - salt: load_pillar_data_on_dogwood_mongodb_nodes

build_mongodb_nodes:
  salt.state:
    - tgt: 'G@roles:mongodb and G@environment:dogwood-qa and not G@roles:mongodb_primary'
    - tgt_type: compound
    - highstate: True
    - require:
        - salt: populate_mine_with_mongodb_node_data
    - pillar:
        mongodb:
          overrides:
            pkgs:
              - mongodb-org
              - python
              - python-pip

build_mongodb_master_node:
  salt.state:
    - tgt: 'G@roles:mongodb_primary and G@environment:dogwood-qa'
    - tgt_type: compound
    - highstate: True
    - require:
        - salt: populate_mine_with_mongodb_node_data
    - pillar:
        mongodb:
          overrides:
            pkgs:
              - mongodb-org
              - python
              - python-pip
