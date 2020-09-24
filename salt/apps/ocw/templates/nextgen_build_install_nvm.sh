#!/bin/bash

set -e

export NVM_DIR=/home/ocw/.nvm
. /home/ocw/.nvm/nvm.sh

nvm install {{ node_version }}

nvm alias default {{ node_version }}
