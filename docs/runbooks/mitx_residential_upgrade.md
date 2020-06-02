# Background
MITx Residential upgrade typically takes place twice a year following OpenedX's named releases and happens between school semesters. To manage the upgrade, Devops has to perform a few taks before and during and scheduled maintancne window outlined below.

## Several days prior to upgrade

#### Communication
- Once a date and time for the downtime is finalized, send request to post scheduled downtime to 3down. Here's an example of the message:
    + The Residential MITx system (lms.mitx.mit.edu, studio.mitx.mit.edu and staging.mitx.mit.edu) will be unavailable starting at `<time>` for an estimated `<time>` hours while we perform routine upgrades. If you have any questions please contact mitx-support@mit.edu
- Update S3 `upgrading.mitx.mit.edu` bucket maintenance html page to reflect maintenance time

### Tech prep
- Build edxapp and worker AMIs (see below)
- Deploy EC2 instances from AMIs
- Smoke-test deployed instances
- Shutdown all supervisor services

## Upgrade window
- Post downtime message on the site by updating the DNS entry for lms and studio to point to the CloudFront Distribution that is configured to use the S3 bucket as its origin
- Stop all edX processes on the current instances
- Run migrations on new instances
- Start all edX processes on the new instances
- Add new instances to ELB
- Remove old instances from ELB
- Verify that site is up and functional by running some manual tests
- Change DNS back to point to ELB

## Creating AMIs

New AMIs are built from the latest Git release branch in our [mitodl/edx-platform](https://github.com/mitodl/edx-platform) repo. This release branch is the edX code plus some patches of our own, specific to our organization; created by rebasing on top of their branch for a particular release.

edX release branches as they appear in edX's upstream repository are named starting with `open-release`; so, for example, the Juniper Release Candidate 3 branch is `upstream/open-release/juniper.rc3` (where my edX upstream repo is named `upstream`).

Our release branches are named starting with `mitx/`, so our edX Juniper release branch, from which our AMIs are built, is `origin/mitx/juniper` (where my MITx origin repo is named `origin`).

Though we build our AMIs from the `mitx/<release codename>` branch, we also keep copies of edX's `open-release` branches for convenience in issuing pull requests against the corresponding branches in `upstream`.

### Updating Git branches

#### The "mitx" release branch

First, a branch is created in our repository for the `mitx/<code name>` release branch for our AMIs:

```
git checkout -b mitx/koa upstream/open-release/koa.master
git push -u origin mitx/koa
```

This is usually branched off of edX's first `.master` branch for the relevant release codename.

#### The pull and rebase

When a new version is approaching maturity, edX cuts release candidate branches and we update our AMI release branch with the changes from these branches. Here is an example with a theoretical Koa Release Candidate 3 branch.

First, we check out our AMI release branch:

```
git checkout mitx/koa
```

This command should only show our ODL patches to the edX code:

```
git log origin/mitx/koa --not upstream/open-release/koa.rc3
```

We then pull in their changes, rebasing ours on top:

```
git pull --rebase upstream open-release/koa.rc3

git push -f origin HEAD  # push mitx/juniper to our Git origin
```

Sometimes we want to push copies of their `open-release` branches, in case we want to issue PRs against them in the future. We don't necessarily do this right away when we perform an upgrade, but here is what we do if the time comes to issue patches.

```
git checkout -b open-release/koa.rc3 upstream/open-release/koa.rc3
git push -u origin open-release/juniper.rc3
```

### AMI build commands

This is the sequence of Salt commands to run to build AMIs and deploy the edX application.

First, build the new AMIs. "Purpose" in this case is "next-residential-draft," but you can pick "draft" or "live." Our convention is to use "draft." This parameter is needed only for pulling in pillar data. This state will create a couple of EC2 "base" instances from which AMI snapshots will be taken.

```
sudo -E PURPOSE=next-residential-draft ENVIRONMENT=mitx-qa RUN_MIGRATIONS=1 salt-run state.orchestrate orchestrate.edx.build_ami
```

If there was an error in the `build_ami` state after the EC2 base instances were provisioned, you can run a highstate like this to try to resume the build:

```
sudo salt edx*mitx-qa*base state.highstate pillar="{'edx': {'ansible_flags': '-e migrate_db=yes'}}"
```

You can iterate over fixing configuration errors with that highstate command, but once things are working you will need to run the `build_ami` above to complete the AMI build.


Next, the Salt database needs to be updated with the IDs of the AMIs that were just built.

```
sudo -E ENVIRONMENT=mitx-qa salt-run state.orchestrate orchestrate.edx.update_edxapp_ami_sdb
```

New EC2 instances are provisioned next from the AMIs, and configured.

```
sudo -E ANSIBLE_FLAGS='--tags install:configuration' PURPOSES='next-residential-draft,next-residential-live' ENVIRONMENT='mitx-qa' salt-run -l debug state.orchestrate orchestrate.edx.deploy
```

The instances are added to the load balancer.

```
sudo -E ENVIRONMENT=mitx-qa PURPOSES=next-residential-draft,next-residential-live salt-run state.orchestrate orchestrate.aws.mitx_elb
```
That does not remove old instances from the load balancer! If it succeeded and the new instances are OK, you need to remove the old ones as follows. This is an example. You need to replace the Salt minion names with the real names of your old instances. The cloud.destroy state does not accept wildcards.

```
salt master-operations-qa cloud.destroy edx-mitx-qa-next-residential-draft-0-v3,edx-mitx-qa-next-residential-live-0-v3,edx-mitx-qa-next-residential-live-1-v3,edx-worker-mitx-qa-next-residential-draft-0-v3,edx-worker-mitx-qa-next-residential-live-0-v3
```

### Updating the edX app configuration or redeploying the code

If you need to update the edX app's configuration later, you can run this state to update the configuration only:

```
salt edx-*mitx-qa-next* state.sls edx.run_ansible pillar="{'edx': {'ansible_flags': '--tags install:configuration'}}"
```

To redeploy; for instance, if there's a new commit to `mitx/<release codename>` in the ODL `edx-platform` repo, try running this:

```
salt edx-*mitx-qa-next* git.fetch /edx/app/edxapp/edx-platform user=edxapp

# Or, if that doesn't work:
salt edx-*mitx-qa-next-residential-* git.reset /edx/app/edxapp/edx-platform/ opts='--hard origin/mitx/juniper' user=edxapp
```

You must restart the application after changing the configuration or redeploying above.

```
salt edx-*mitx-qa-next-residential-* supervisord.restart all bin_env=/edx/bin/supervisorctl
```