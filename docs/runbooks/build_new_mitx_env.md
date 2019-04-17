In order to provision a new MITx environment the following steps are necessary:

- Define the environment in the `environment_settings.yml` file in the pillar repository
- Provision the VPC
  `VPC_NAME='My VPC' ENVIRONMENT=my-vpc BUSINESS_UNIT=residential salt-run state.orchestrate orchestrate.aws.mitx`
- Accept the VPC peering connection via the AWS console
- Update the route tables in the operations VPC to allow traffic from the new environment
- Update the operations security groups for Consul and FluentD to allow traffic from the new environment
- Deploy the Consul nodes
  `VPC_NAME='My VPC' ENVIRONMENT=my-vpc BUSINESS_UNIT=residential salt-run state.orchestrate orchestrate.edx.services.consul`

- Deploy the RabbitMQ, RDS, MongoDB, and Elasticsearch nodes
  ```
  export VPC_NAME='My VPC'
  export ENVIRONMENT=my-vpc
  export BUSINESS_UNIT=residential
  salt-run state.orchestrate orchestrate.edx.services.rds
  salt-run state.orchestrate orchestrate.edx.services.mongodb
  salt-run state.orchestrate orchestrate.edx.services.elasticsearch
  salt-run state.orchestrate orchestrate.edx.services.rabbitmq
  ```
- Create the MySQL schemas
  `VPC_NAME='My VPC' ENVIRONMENT=my-vpc BUSINESS_UNIT=residential salt-run state.orchestrate orchestrate.edx.mysql_schemas`
- Deploy the edX app, worker, and xqueue-watcher instances
  ```
  export VPC_NAME='My VPC'
  export ENVIRONMENT=my-vpc
  export BUSINESS_UNIT=residential
  export PURPOSE_PREFIX=residential
  salt-run state.orchestrate orchestrate.edx.deploy
  ```
- Deploy the AWS ELB
  `VPC_NAME='My VPC' ENVIRONMENT=my-vpc BUSINESS_UNIT=residential salt-run state.orchestrate orchestrate.aws.mitx_elb`
