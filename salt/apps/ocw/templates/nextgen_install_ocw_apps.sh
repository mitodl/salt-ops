#!/bin/bash

set -e

cd /opt/ocw/ocw-to-hugo
npm install .

cd /opt/ocw/hugo-course-publisher
yarn install --pure-lockfile
