# Open CourseWare

[Table of Contents](index.md)

## Code Deployment

The [`ocwcms` repository](https://github.com/mitocw/ocwcms) contains the code, page assets, and other resources for the OCW origin and CMS servers.

Files in the `web` folder get published to the origin *and* CMS webservers and consist of static assets loaded on the user-facing site, such as HTML, CSS, and Javascript files. They are mainly needed on the origin webservers, but they should also be pushed to the CMS servers so that course ZIP files get created with the latest page assets.

Files in `publishing` get published to the engine (CMS 2) server, and are mostly programs and scripts.

Files in `plone` get published to the Plone CMS on CMS 1 and CMS 2, and are mostly Python and Plone page template files, which govern how the site looks and behaves. There are also views that control how the CMS functions for maintainers, and which define metadata endpoints.

We automate deployments with Salt, and the state that is run for deployment ([sync_repo.sls](https://github.com/mitodl/salt-ops/blob/f41844f3bb4fc2c38f06bd8a5760e583097ec3df/salt/apps/ocw/sync_repo.sls)) is in the [`salt-ops` repository](https://github.com/mitodl/salt-ops).

All servers in our production environment pull from the `master` branch of the repository, and those in the QA environment pull from the `qa` tag. The `qa` tag can be assigned to any git ref (branch, tag, or commit) in order to put changes into QA before they are merged to `master`.

Plone will need to be [restarted](howto_restartcms.md) after any code in `plone` is published to the CMS.


### Examples

Tagging a branch for deployment to QA:

```
$ # Tagging a branch that I have checked out and have just pushed:
$ git tag -f qa mybranch
$ # Tagging it without pulling it down locally:
$ git tag -f qa origin/Increasing_batch_number
$ # In either case, pushing the tag to Github:
$ git push -f origin qa
```

Deploying `ocwcms` to all QA servers (run on the Salt master):

```
$ sudo salt -C 'P@roles:ocw-(origin|cms) and G@ocw-environment:qa' state.sls apps.ocw.sync_repo
```

Deploying `ocwcms` to production (run on the Salt master):

```
$ sudo salt -C 'P@roles:ocw-(origin|cms) and G@ocw-environment:production' state.sls apps.ocw.sync_repo
```
