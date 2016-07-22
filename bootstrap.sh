#!/bin/bash

sudo apt-get -y install curl
if [ -z `which salt-minion` ]
then
    curl -o install_salt.sh -L https://bootstrap.saltstack.com
    sudo sh install_salt.sh -M -U -Z -L -P -A 127.0.0.1 stable
fi
sudo mkdir -p /srv/salt
sudo mkdir -p /srv/pillar
sudo sh scripts/update_files.sh
sudo salt-call --local grains.set roles '[master]'
sudo salt-call --local service.restart salt-minion
sudo salt-key -A -y
sudo salt -G 'roles:master' state.sls master_utils.libgit
sudo salt -G 'roles:master' state.sls master_utils.bootstrap
sudo salt-call --local service.restart salt-master
sleep 5
sudo salt -G 'roles:master' state.highstate
