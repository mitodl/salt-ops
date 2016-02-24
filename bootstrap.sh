#!/bin/bash

sudo apt-get install git
git clone https://github.com/mitodl/master-formula
sh master-formula/scripts/build.sh
sudo cp -r pillar/* /srv/pillar
sudo cp -r salt/* /srv/salt
sudo salt-call --local state.highstate
