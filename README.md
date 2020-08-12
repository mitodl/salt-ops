Salt Ops
========

This repository contains the salt code and configuration data that is used by the operations team at the [MIT Office of Open Learning](https://openlearning.mit.edu) to manage our applications and infrastructure.

Points of Interest
------------------
`/salt`: This directory contains all of the state files, orchestrate scripts, and reactor code

`/pillar`: This directory contains all of the pillar data that is used to configure the various environments, applications, and infrastructure

`/docs`: The documentation (such as it is) for various aspects of our infrastructure, runbooks, etc.

`/packer`: This is where packer configuration files for the different systems we need to build and deploy are maintained. This also contains a subdirectory of minion configs to be used during build time.
