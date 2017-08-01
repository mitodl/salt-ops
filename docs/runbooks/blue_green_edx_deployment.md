# Background
Blue/Green deployments are a methodology whereby a "blue" set of servers is running in production and a second "green"
set is provisioned alongside them with the new software. Once the "green" servers are active they are added to the load
balancer that controls access to the overall set of production hosts. Once the load balancer identifies the "green"
nodes as healthy then the "blue" nodes are removed from circulation.

# Building A Release Artifact
There is an orchestrate script (`orchestrate.edx.build_ami`) that will create, configure, and then snapshot an edX
application and worker node. As part of this process the value stored in the SDB URL
`sdb://consul/edxapp-release-version` is incremented and included as part of the AMI name as well as being set in the
`release-version` grain on the deployed instances.

A second orchestrate script (`orchestrate.edx.update_edxapp_ami_sdb`) must then be run to update the AMI Ids stored in
SDB that get rendered into the edX cloud profile. This updated AMI ID is what will be used for successive deployments of
MITx production and/or QA instances.

# Deploying
Once the AMI has been created and the SDB values updated then the `orchestrate.edx` routine can be executed to deploy a
new set of instances to the target environment. The currently running instances do not get overridden, nor do they
prevent deployment of new instances, because the `release_version` is incorporated in the instance name/minion id. This
results in a "blue" set of servers that are identified by having a `release-version` grain and minion id suffix
containing the previous version. The "green" servers are identifiable by the fact that they have the current release
version set on them.

Once the "green" instances are deployed and the highstate run completes then you should run a smoke test against them to
ensure that they can serve traffic and the MITx theme has been properly applied. You can then run the
'orchestrate.aws.mitx_elb` routine to add them to the load balancer. As soon as they are marked as healthy and serve
traffic then the "blue" hosts can be removed.

As soon as you feel comfortable that the "green" hosts are able to serve traffic without error and no rollback is
required then you can terminate the "blue" hosts.
