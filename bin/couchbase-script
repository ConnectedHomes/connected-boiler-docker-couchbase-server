#!/bin/bash

cleanup() {
  /etc/init.d/couchbase-server stop
  exit 0
}

/etc/init.d/couchbase-server start

trap cleanup SIGTERM SIGINT

tail -F /opt/couchbase/var/lib/couchbase/logs/couchdb.1 &

# hack to artificially keep the container up
while :; do sleep 1; done
