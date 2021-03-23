#!/bin/bash

# There's no Salt state to run this script. We only have one Kibana instance
# per environment, so it's easier to just copy and run this script or these
# commands on the instance.

set -e

systemctl stop kibana
cp -p /etc/kibana/kibana.yml /etc/kibana/kibana.yml.backup-pre-upgrade
dpkg -P kibana
grep -v 'artifacts.elastic.co' /etc/apt/sources.list > /tmp/sources.list && mv /tmp/sources.list /etc/apt/sources.list
apt-get update
apt-get clean
wget -qO - https://d3g5vo6xdbdb9a.cloudfront.net/GPG-KEY-opendistroforelasticsearch | apt-key add -
echo "deb https://d3g5vo6xdbdb9a.cloudfront.net/apt stable main" | tee -a /etc/apt/sources.list.d/opendistroforelasticsearch.list
apt-get update
apt-get install -y opendistroforelasticsearch-kibana
cp -p /etc/kibana/kibana.yml.backup-pre-upgrade /etc/kibana/kibana.yml
/usr/share/kibana/bin/kibana-plugin --allow-root remove opendistroSecurityKibana
systemctl daemon-reload
systemctl enable kibana.service
systemctl start kibana
