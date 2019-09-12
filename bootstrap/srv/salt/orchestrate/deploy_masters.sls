{% set subnet_ids = salt.boto_vpc.describe_subnets(
    vpc_id=salt.boto_vpc.describe_vpcs(
        name='mitodl-operations-services').vpcs[0].id
    ).subnets|rejectattr('availability_zone', '==', 'us-east-1e')|map(attribute='id')|list %}
{% set secgroups = [] %}
{% for group_name in security_groups %}
{% do secgroups.append(salt.boto_secgroup.get_group_id(
  '{}-{}'.format(group_name, ENVIRONMENT), vpc_name=VPC_NAME) %}
{% endfor %}
