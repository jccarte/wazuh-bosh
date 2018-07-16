#!/bin/bash
# Russ Thompson 2018
# Download threat intelligence from S3 bucket, it's already preformatted via Jenkins for Wazuh.
# See for more:  https://ci-internal.carekinesis.net/job/SecOps-threat-lists
# Place this script in /etc/cron.hourly and make executable

# Get the full path to wazuh
WAZUH_PATH="$(cd /var/vcap/packages/wazuh-server/wazuh-* ; pwd)"

# STATIC: The on disk file we will use to place our threat intelligence (must be in cdb format, without .cbd extension)
readonly THREAT_CDB_FILE="$WAZUH_PATH/etc/lists/emerging-threat-list"
# The S3 bucket is public, as it's just threat intelligence from public sources
readonly S3_CDB_FILE="https://s3.amazonaws.com/secops-ip-lists/emerging-threat-list.cdb"


curl --silent $S3_CDB_FILE | uniq > $THREAT_CDB_FILE
if [ "$?" -eq "0" ] ; then
  THREAT_COUNT=$(wc -l $THREAT_CDB_FILE | awk '{print $1}')
  logger -t $(basename -- "$0") "[INFO] Updating threat list, latest threat count: [$THREAT_COUNT]"
  chown ossec:ossec $THREAT_CDB_FILE
  $WAZUH_PATH/bin/ossec-makelists
  rm -f $THREAT_CDB_FILE ; sleep 2
  # Check that the cdb file has been compiled before restarting Wazuh.
  if [ -f "$THREAT_CDB_FILE.cdb" ] ; then
    $WAZUH_PATH/bin/ossec-control restart
  else
    logger -t $(basename -- "$0") "[ERROR] Wazuh did not compile the CDB file, check Wazuh config (OSSEC.conf)"
  fi
else
  logger -t $(basename -- "$0") "[ERROR], error encountered while ingesting threat intelligence: [$THREAT_COUNT]"
fi
