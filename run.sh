#!/bin/bash

cleanup() {
  /etc/init.d/couchbase-server stop
  exit 0
}

echo "NODE_ENV: ${NODE_ENV}"
if [[ ${NODE_ENV} = 'test' ]]; then
  COMMAND="sudo mount -t tmpfs -o size=200M tmpfs /opt/couchbase/var"
  echo about to $COMMAND
  sudo mount -t tmpfs -o size=200M tmpfs /opt/couchbase/var
fi

mkdir -p /opt/couchbase/var/lib/couchbase/logs
chown -R couchbase:couchbase /opt/couchbase

/etc/init.d/couchbase-server start

trap cleanup SIGTERM SIGINT

tail -F /opt/couchbase/var/lib/couchbase/logs/couchdb.1 &

# hack to artificially keep the container up
while :; do sleep 1; done
