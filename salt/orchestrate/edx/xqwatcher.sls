{% from "orchestrate/aws_env_macro.jinja" import VPC_NAME, VPC_RESOURCE_SUFFIX,
 ENVIRONMENT, BUSINESS_UNIT, subnet_ids with context %}

load_xqwatcher_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/xqwatcher.conf
    - source: salt://orchestrate/aws/cloud_profiles/xqwatcher.conf
    - template: jinja

generate_xqwatcher_cloud_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/{{ ENVIRONMENT }}_xqwatcher_map.yml
    - source: salt://orchestrate/aws/map_templates/instance_map.yml
    - template: jinja
    - makedirs: True
    - context:
        service_name: xqwatcher
        environment_name: {{ ENVIRONMENT }}
        num_instances: 5
        tags:
          business_unit: {{ BUSINESS_UNIT }}
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
  salt.runner:
    - name: cloud.map_run
    - path: /etc/salt/cloud.maps.d/{{ ENVIRONMENT}}_xqwatcher_map.yml
    - kwargs:
        parallel: True
    - require:
        - file: generate_xqwatcher_cloud_map_file

build_xqwatcher_nodes:
  salt.state:
    - tgt: 'G@roles:xqwatcher and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - highstate: True
