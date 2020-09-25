#!/bin/bash

set -e

cd /home/ocw/ocw-to-hugo
npm install .

cd /home/ocw/hugo-course-publisher
yarn install --pure-lockfile
