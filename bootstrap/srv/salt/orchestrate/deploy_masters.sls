{% set aws_access_key = salt.sdb.get('sdb://osenv/AWS_ACCESS_KEY_ID') %}
{% set aws_secret_access_key = salt.sdb.get('sdb://osenv/AWS_SECRET_ACCESS_KEY') %}
{% set ENVIRONMENT = salt.sdb.get('sdb://osenv/ENVIRONMENT') %}
{% set env_data = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set VPC_NAME = env_data.environments[ENVIRONMENT].vpc_name %}
{% set subnet_ids = salt.boto_vpc.describe_subnets(
    vpc_id=salt.boto_vpc.describe(
        vpc_name=VPC_NAME,
        keyid=aws_access_key,
        key=aws_secret_access_key).vpc.id
    ).subnets|rejectattr('availability_zone', '==', 'us-east-1e')|map(attribute='id')|list %}
{% set security_groups = ['consul-agent-' ~ ENVIRONMENT, 'salt-master-' ~ ENVIRONMENT, 'default'] %}
{% set secgroupids = [] %}
{% for group_name in security_groups %}
{% do secgroupids.append(salt.boto_secgroup.get_group_id(group_name, vpc_name=VPC_NAME)) %}
{% endfor %}
{% if 'qa' in ENVIRONMENT %}
{% set suffix = 'qa' %}
{% else %}
{% set suffix = 'production' %}
{% endif %}

deploy_salt_master_for_{{ ENVIRONMENT }}:
  salt.runner:
    - name: cloud.map_run
    - kwargs:
        map_data:
          salt_master:
            - master-operations-{{ suffix }}:
                grains:
                  roles:
                    - master
                    - master-{{ suffix }}
                  purpose: salt-{{ suffix }}
                network_interfaces:
                  - DeviceIndex: 0
                    AssociatePublicIpAddress: True
                    SubnetId: {{ subnet_ids[0] }}
                    SecurityGroupId: {{ secgroupids }}
                tag:
                  environment: operations
                  role: master-{{ suffix }}
                  OU: operations
                  Environment: operations
