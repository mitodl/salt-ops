# Bootstrapping Salt Masters
In order to allow for (re)building our infrastructure we need to be able to deploy one or more salt masters. This directory contains the configurations and steps necessary to launch a master in a cloud environment.

## Setup
Before running the bootstrapping you need to have Salt installed locally. The easiest way to do so without polluting your Python packages is to use [Pipenv](https://docs.pipenv.org/en/latest/). Once you have pipenv installed just run:

```
pipenv install
```

## Steps
To deploy the masters, run the following:

```
pipenv shell
export AWS_ACCESS_KEY_ID=<your access key ID>
export AWS_SECRET_ACCESS_KEY=<your secret access key>
salt-run -c bootstrap/etc/salt/ state.orchestrate orchestrate.deploy_masters
salt-run -c bootstrap/etc/salt/ state.orchestrate orchestrate.configure_masters
```
