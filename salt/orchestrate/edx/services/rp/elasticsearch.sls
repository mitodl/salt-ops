{% set subnet_ids = [] %}
{% for subnet in salt.boto_vpc.describe_subnets(subnet_names=[
    'public1-dogwood-rp', 'public2-dogwood-rp', 'public3-dogwood-rp'])['subnets'] %}
{% do subnet_ids.append('{0}'.format(subnet['id'])) %}
{% endfor %}

load_elasticsearch_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/elasticsearch.conf
    - source: salt://orchestrate/aws/cloud_profiles/elasticsearch.conf

generate_elasticsearch_cloud_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/dogwood_qa_elasticsearch_map.yml
    - source: salt://orchestrate/aws/map_templates/elasticsearch.yml
    - template: jinja
    - makedirs: True
    - context:
        environment_name: dogwood-rp
        roles:
          - elasticsearch
        securitygroupid:
          - {{ salt.boto_secgroup.get_group_id(
            'elasticsearch-dogwood-rp', vpc_name='Dogwood RP') }}
          - {{ salt.boto_secgroup.get_group_id(
            'salt_master-dogwood-rp', vpc_name='Dogwood RP') }}
        subnetids: {{ subnet_ids }}
    - require:
        - file: load_elasticsearch_cloud_profile

deploy_elasticsearch_nodes:
  salt.function:
    - name: saltutil.runner
    - tgt: 'roles:master'
    - tgt_type: grain
    - arg:
        - cloud.map_run
    - kwarg:
        path: /etc/salt/cloud.maps.d/dogwood_qa_elasticsearch_map.yml
        parallel: True
    - require:
        - file: generate_elasticsearch_cloud_map_file

load_pillar_data_on_dogwood_elasticsearch_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:elasticsearch and G@environment:dogwood-rp'
    - tgt_type: compound
    - require:
        - salt: deploy_elasticsearch_nodes

populate_mine_with_dogwood_elasticsearch_data:
  salt.function:
    - name: mine.update
    - tgt: 'G@roles:elasticsearch and G@environment:dogwood-rp'
    - tgt_type: compound
    - require:
        - salt: load_pillar_data_on_dogwood_elasticsearch_nodes

{# Reload the pillar data to update values from the salt mine #}
reload_pillar_data_on_dogwood_elasticsearch_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:elasticsearch and G@environment:dogwood-rp'
    - tgt_type: compound
    - require:
        - salt: populate_mine_with_dogwood_elasticsearch_data

install_git_on_elasticsearch_nodes_for_cloning_forked_python_packages:
  salt.function:
    - name: pkg.install
    - tgt: 'G@roles:elasticsearch and G@environment:dogwood-rp'
    - tgt_type: compound
    - arg:
        - git

build_dogwood_elasticsearch_nodes:
  salt.state:
    - tgt: 'G@roles:elasticsearch and G@environment:dogwood-rp'
    - tgt_type: compound
    - highstate: True
    - require:
        - salt: reload_pillar_data_on_dogwood_elasticsearch_nodes

remove_broken_line_from_elasticsearch_init_script:
  file.comment:
    - name: /etc/init.d/elasticsearch
    - regex: ^test "\$START_DAEMON"
    - mode: Delete
  cmd.run:
    - name: systemctl daemon-reload && systemctl restart elasticsearch
