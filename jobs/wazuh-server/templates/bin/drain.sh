#!/bin/bash

set -e # exit immediately if a simple command exits with a non-zero status
set -u # report the usage of uninitialized variables

cp /var/vcap/packages/wazuh-server/wazuh-server-3.2.1/etc/client.keys /var/vcap/store/wazuh-server/client.keys
echo "client.keys copied" > /var/vcap/sys/log/wazuh-server/drain.log
echo 1; exit 0