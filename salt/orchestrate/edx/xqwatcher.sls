{% set net_map = {'Dogwood QA': '10.5', 'Dogwood RP': '10.6'} %}
{% set VPC_NAME = salt.environ.get('VPC_NAME', 'Dogwood QA') %}
{% set VPC_RESOURCE_SUFFIX = salt.environ.get('VPC_RESOURCE_SUFFIX',
                                              VPC_NAME.lower() | replace(' ', '-')) %}
{% set VPC_NET_PREFIX = net_map[VPC_NAME] %}
{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT', 'dogwood-qa') %}
{% set subnet_ids = [] %}
{% for subnet in salt.boto_vpc.describe_subnets(subnet_names=[
    'public1-{}'.format(VPC_RESOURCE_SUFFIX), 'public2-{}'.format(VPC_RESOURCE_SUFFIX), 'public3-{}'.format(VPC_RESOURCE_SUFFIX)])['subnets'] %}
{% do subnet_ids.append('{0}'.format(subnet['id'])) %}
{% endfor %}

load_xqwatcher_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/xqwatcher.conf
    - source: salt://orchestrate/aws/cloud_profiles/xqwatcher.conf

generate_xqwatcher_cloud_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/{{ ENVIRONMENT }}_xqwatcher_map.yml
    - source: salt://orchestrate/aws/map_templates/xqwatcher.yml
    - template: jinja
    - makedirs: True
    - context:
        environment_name: {{ ENVIRONMENT }}
        roles:
          - xqwatcher
        securitygroupid:
          - {{ salt.boto_secgroup.get_group_id(
            'salt_master-{}'.format(VPC_RESOURCE_SUFFIX), vpc_name=VPC_NAME) }}
        subnetids: {{ subnet_ids }}
    - require:
        - file: load_xqwatcher_cloud_profile

ensure_instance_profile_exists_for_xqwatcher:
  boto_iam_role.present:
    - name: xqwatcher-instance-role

deploy_xqwatcher_cloud_map:
  salt.function:
    - name: saltutil.runner
    - tgt: 'roles:master'
    - tgt_type: grain
    - arg:
        - cloud.map_run
    - kwarg:
        path: /etc/salt/cloud.maps.d/{{ ENVIRONMENT}}_xqwatcher_map.yml
        parallel: True
    - require:
        - file: generate_xqwatcher_cloud_map_file

build_xqwatcher_nodes:
  salt.state:
    - tgt: 'G@roles:xqwatcher and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - highstate: True
