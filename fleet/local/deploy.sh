#!/bin/bash

set -e

export FLEETCTL_STRICT_HOST_KEY_CHECKING=false

docker build -t couchbase $(dirname $0)/../../

fleetctl destroy couchbase.service
sleep 1
fleetctl start $(dirname $0)/couchbase.service
