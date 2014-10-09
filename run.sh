#!/bin/bash

cleanup() {
  /etc/init.d/couchbase-server stop
  exit 0
}

echo "NODE_ENV: ${NODE_ENV}"
if [[ ${NODE_ENV} = 'test' ]]; then
  mkdir -p /opt/couchbase/var/lib
  COMMAND="sudo mount -t tmpfs -o size=200M tmpfs /opt/couchbase/var"
  echo about to $COMMAND
  sudo mount -t tmpfs -o size=200M tmpfs /opt/couchbase/var
  cd /opt/couchbase
  mkdir -p var/lib/couchbase var/lib/couchbase/config var/lib/couchbase/data \
    var/lib/couchbase/stats var/lib/couchbase/logs var/lib/moxi

  chown -R couchbase:couchbase var
  cd -
fi

/etc/init.d/couchbase-server start

trap cleanup SIGTERM SIGINT

tail -F /opt/couchbase/var/lib/couchbase/logs/couchdb.1 &

# hack to artificially keep the container up
while :; do sleep 1; done
