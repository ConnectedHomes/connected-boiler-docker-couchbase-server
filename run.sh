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

if [[ "${SET_EC2_HOSTNAME}" ]]; then 
  # in ec2, we assign couchbase node the ec2 public hostname
  # however, it will error because it cannot bind to the resolved IP
  # address. Setting it to 127.0.0.1 will workaround this.
  EC2_HOSTNAME=$(curl -sS http://169.254.169.254/latest/meta-data/public-hostname) 
  echo "127.0.0.1 ${EC2_HOSTNAME}" >> /etc/hosts 
fi

tail -F /opt/couchbase/var/lib/couchbase/logs/couchdb.1 &

# hack to artificially keep the container up
while :; do sleep 1; done
