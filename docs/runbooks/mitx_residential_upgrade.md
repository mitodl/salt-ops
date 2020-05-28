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
