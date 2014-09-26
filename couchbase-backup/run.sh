#!/bin/bash

set -e

rm -rf /backups /backups-dd

timestamp=$(date +"%Y%m%d.%H%M.%S")
host=http://${COUCHBASE_PORT_8091_TCP_ADDR}:8091

echo "backing up couchbase cluster"
/opt/couchbase/bin/cbbackup -u Administrator -p password $host /backups > /dev/null 2>&1

echo "backing up couchbase design docs"
/opt/couchbase/bin/cbbackup -u Administrator -p password -x design_doc_only=1 $host /backups-dd > /dev/null 2>&1

# upload to s3
echo "uploading backups to s3"
aws s3 cp --recursive /backups/* s3://connectedboiler-couchbase/backups/$timestamp/
aws s3 cp --recursive /backups-dd/* s3://connectedboiler-couchbase/backups/$timestamp/
