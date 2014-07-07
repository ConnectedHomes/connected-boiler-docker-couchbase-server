#!/bin/bash

set -e

export FLEETCTL_TUNNEL=coreos1.bgchtest.info
export FLEETCTL_STRICT_HOST_KEY_CHECKING=false

docker build -t couchbase $(dirname $0)/../../
docker tag couchbase registry.bgchtest.info:5000/couchbase
docker push registry.bgchtest.info:5000/couchbase

for n in {1..3}
do
  fleetctl destroy couchbase.$n.service
  sleep 1
  fleetctl start $(dirname $0)/couchbase.$n.service
done
