#!/bin/bash

sudo cp -r cloud.maps.d /etc/salt
sudo cp -r cloud.profiles.d /etc/salt/
sudo cp -r salt/* /srv/salt/
sudo cp -r pillar/* /srv/pillar
