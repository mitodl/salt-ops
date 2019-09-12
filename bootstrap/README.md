# Bootstrapping Salt Masters
In order to allow for (re)building our infrastructure we need to be able to deploy one or more salt masters. This directory contains the configurations and steps necessary to launch a master in a cloud environment.

## Setup
Before running the bootstrapping you need to have Salt installed locally. The easiest way to do so without polluting your Python packages is to use [pipx](https://pipxproject.github.io/pipx/). Once you have pipx installed just run:

```
pipx install salt
pipx inject salt gitpython
```

## Steps
To deploy the masters, run the following:

```
export AWS_ACCESS_KEY=<your access key ID>
export AWS_SECRET_ACCESS_KEY=<your secret access key>
```
