#!/bin/bash

sudo apt-get -y install git
mkdir formulas
git clone https://github.com/mitodl/master-formula formulas/master-formula
sh formulas/master-formula/scripts/build.sh
sudo cp -r pillar/* /srv/pillar
sudo cp -r salt/* /srv/salt
# sudo mkdir /etc/salt/spm.repos.d
# sudo spm create_repo /srv/spm
# sudo spm build formulas/master-formula
# echo "\
# local_repo:
#   url: file:///srv/spm" | sudo tee /etc/salt/spm.repos.d/local_repo.conf
# sudo spm update_repo
# sudo spm install master
sudo cp -r formulas/master-formula/master /srv/salt
sudo salt-call --local state.highstate
