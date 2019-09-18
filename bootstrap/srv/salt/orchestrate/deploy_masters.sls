{% set aws_access_key = salt.sdb.get('sdb://osenv/AWS_ACCESS_KEY_ID') %}
{% set aws_secret_access_key = salt.sdb.get('sdb://osenv/AWS_SECRET_ACCESS_KEY') %}
{% do salt.log.debug('AWS credentials are ' ~ aws_access_key ~ ' and ' ~ aws_secret_access_key) %}
{% do salt.log.debug('VPC Data is: ' ~ salt.boto_vpc.describe(vpc_name='mitodl-operations-services', keyid=aws_access_key, key=aws_secret_access_key)) %}
{% set subnet_ids = salt.boto_vpc.describe_subnets(
    vpc_id=salt.boto_vpc.describe(
        vpc_name='mitodl-operations-services',
        keyid=aws_access_key,
        key=aws_secret_access_key).vpc.id
    ).subnets|rejectattr('availability_zone', '==', 'us-east-1e')|map(attribute='id')|list %}
{% set VPC_NAME = 'mitodl-operations-services' %}
{% set ENVIRONMENT = 'operations' %}
{% set security_groups = ['consul-agent-' ~ ENVIRONMENT, 'salt-master', 'default'] %}
{% set secgroupids = [] %}
{% for group_name in security_groups %}
{% do secgroupids.append(salt.boto_secgroup.get_group_id(group_name, vpc_name=VPC_NAME)) %}
{% endfor %}

deploy_salt_masters_cloud_map:
  salt.runner:
    - name: cloud.map_run
    - kwargs:
        parallel: True
        map_data:
          salt_master:
            - master-operations-production:
                grains:
                  roles:
                    - master
                    - master-production
                network_interfaces:
                  - DeviceIndex: 0
                    AssociatePublicIpAddress: True
                    SubnetId: {{ subnet_ids[1] }}
                    SecurityGroupId: {{ secgroupids }}
                tag:
                  environment: operations
                  role: master-production
                  OU: operations
                  Environment: operations
            - master-operations-qa:
                grains:
                  roles:
                    - master
                    - master-qa
                network_interfaces:
                  - DeviceIndex: 0
                    AssociatePublicIpAddress: True
                    SubnetId: {{ subnet_ids[0] }}
                    SecurityGroupId: {{ secgroupids }}
                tag:
                  environment: operations
                  role: master-qa
                  OU: operations
                  Environment: operations
