#!/bin/bash

set -e

systemctl stop elasticsearch
cp -p /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.backup-pre-upgrade
dpkg -P elasticsearch
grep -v 'artifacts.elastic.co' /etc/apt/sources.list > /tmp/sources.list && mv /tmp/sources.list /etc/apt/sources.list
dpkg -P ca-certificates-java openjdk-8-jre-headless
grep -v 'ftp.us.debian.org/debian/ stretch main contrib non-free' /etc/apt/sources.list > /tmp/sources.list && mv /tmp/sources.list /etc/apt/sources.list
apt-get update
apt-get clean
apt-get install -y software-properties-common dirmngr apt-transport-https unzip
echo "deb http://deb.debian.org/debian stretch-backports main" > /etc/apt/sources.list.d/backports.list
apt-get update
apt-get install -y openjdk-11-jdk
wget -qO - https://d3g5vo6xdbdb9a.cloudfront.net/GPG-KEY-opendistroforelasticsearch | apt-key add -
echo "deb https://d3g5vo6xdbdb9a.cloudfront.net/apt stable main" | tee -a /etc/apt/sources.list.d/opendistroforelasticsearch.list
apt-get update
cd /var/tmp
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-oss-7.10.2-amd64.deb
dpkg -i elasticsearch-oss-7.10.2-amd64.deb
rm elasticsearch-oss-7.10.2-amd64.deb
apt-get install -y opendistro-index-management opendistro-alerting opendistro-job-scheduler
cp -p /etc/elasticsearch/elasticsearch.yml.backup-pre-upgrade /etc/elasticsearch/elasticsearch.yml
systemctl start elasticsearch
