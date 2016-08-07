{% set subnet_ids = [] %}
{% for subnet in salt.boto_vpc.describe_subnets(subnet_names=[
    'public1-dogwood-rp', 'public2-dogwood-rp', 'public3-dogwood-rp'])['subnets'] %}
{% do subnet_ids.append('{0}'.format(subnet['id'])) %}
{% endfor %}

load_edx_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/edx.conf
    - source: salt://orchestrate/aws/cloud_profiles/edx.conf

generate_edx_cloud_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/dogwood_rp_edx_map.yml
    - source: salt://orchestrate/aws/map_templates/edx.yml
    - template: jinja
    - makedirs: True
    - context:
        environment_name: dogwood-rp
        roles:
          - edx
          - log-forwarder
        securitygroupid:
          - {{ salt.boto_secgroup.get_group_id(
              'edx-dogwood-rp', vpc_name='Dogwood QA') }}
          - {{ salt.boto_secgroup.get_group_id(
            'salt_master-dogwood-rp', vpc_name='Dogwood QA') }}
        subnetids: {{ subnet_ids }}
        app_types:
          draft: 4
          live: 6
    - require:
        - file: load_edx_cloud_profile

ensure_instance_profile_exists_for_edx:
  boto_iam_role.present:
    - name: edx-instance-role

deploy_edx_cloud_map:
  salt.function:
    - name: saltutil.runner
    - tgt: 'roles:master'
    - tgt_type: grain
    - arg:
        - cloud.map_run
    - kwarg:
        path: /etc/salt/cloud.maps.d/dogwood_rp_edx_map.yml
        parallel: True
    - require:
        - file: generate_edx_cloud_map_file

load_pillar_data_on_edx_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:edx and G@environment:dogwood-rp'
    - tgt_type: compound
    - require:
        - salt: deploy_edx_cloud_map

populate_mine_with_edx_node_data:
  salt.function:
    - name: mine.update
    - tgt: 'G@roles:edx and G@environment:dogwood-rp'
    - tgt_type: compound
    - require:
        - salt: load_pillar_data_on_edx_nodes

{# Reload the pillar data to update values from the salt mine #}
reload_pillar_data_on_edx_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:edx and G@environment:dogwood-rp'
    - tgt_type: compound
    - require:
        - salt: populate_mine_with_edx_node_data

{# Deploy Consul agent first so that the edx deployment can use provided DNS endpoints #}
deploy_consul_agent_to_edx_nodes:
  salt.state:
    - tgt: 'G@roles:edx and G@environment:dogwood-rp'
    - tgt_type: compound
    - sls:
        - consul
        - consul.dns_proxy

build_edx_nodes:
  salt.state:
    - tgt: 'G@roles:edx and G@environment:dogwood-rp'
    - tgt_type: compound
    - highstate: True
    - require:
        - salt: deploy_consul_agent_to_edx_nodes
