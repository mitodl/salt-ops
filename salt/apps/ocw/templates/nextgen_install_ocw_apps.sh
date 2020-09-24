#!/bin/bash

set -e

export NVM_DIR=/home/ocw/.nvm
. /home/ocw/.nvm/nvm.sh

cd /home/ocw/ocw-to-hugo
npm install -g .

cd /home/ocw/hugo-course-publisher
yarn install --pure-lockfile
