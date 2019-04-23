In order to provision a new MITx environment the following steps are necessary:

- Define the environment in the `environment_settings.yml` file in the pillar repository
- Provision the VPC
  `VPC_NAME='My VPC' ENVIRONMENT=my-vpc BUSINESS_UNIT=residential salt-run state.orchestrate orchestrate.aws.mitx`
- Accept the VPC peering connection via the AWS console
- Update the route tables in the operations VPC to allow traffic from the new environment
- Update the operations security groups for Consul and FluentD to allow traffic from the new environment
- Associate the `private.odl.mit.edu` hosted zone with the newly created VPC
- Deploy the Consul nodes
  `VPC_NAME='My VPC' ENVIRONMENT=my-vpc BUSINESS_UNIT=residential salt-run state.orchestrate orchestrate.edx.services.consul`

- Generate MongoDB cluster key
    `salt master vault.write secret-{{ business_unit }}/{{ enviornment }}/mongodb-cluster-key value='salt master vault.write transit/random/750 --output json | jq '.master.data.random_bytes'`
- Deploy the RabbitMQ, RDS, MongoDB, Elasticsearch, and Elasticache Memcached nodes
  ```
  export ENVIRONMENT=my-env
  salt-run state.orchestrate orchestrate.aws.rds
  salt-run state.orchestrate orchestrate.services.mongodb
  salt-run state.orchestrate orchestrate.services.elasticsearch
  salt-run state.orchestrate orchestrate.services.rabbitmq
  salt-run state.orchestrate orchestrate.aws.elasticache
  ```
- Add new environment name to pillar/vault/roles/mitx.sls
- Update consul cluster config
    `salt consul-{{ environment }}-*` state.sls consul.config
- Create the MySQL schemas
  `VPC_NAME='My VPC' ENVIRONMENT=my-vpc BUSINESS_UNIT=residential salt-run state.orchestrate orchestrate.edx.mysql_schemas`
- Build the edX app and worker AMI's
  ```
  export ENVIRONMENT=my-vpc
  export PURPOSE=residential
  salt-run state.orchestrate orchestrate.edx.build_ami
  ```
- Update SDB to point to the AMI and then destory instances
    `salt-run state.orchestrate orchestrate.edx.update_edxapp_ami_sdb`
- Build instances using new AMI's:
    `sudo -E ANSIBLE_FLAGS='--tags install:configuration' PURPOSES='my-purpose' ENVIRONMENT='my-env' salt-run -l debug state.orchestrate orchestrate.edx.deploy`
- Deploy the AWS ELB
  `VPC_NAME='My VPC' ENVIRONMENT=my-vpc BUSINESS_UNIT=residential salt-run state.orchestrate orchestrate.aws.mitx_elb`
