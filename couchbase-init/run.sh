#!/bin/bash -x

untilsuccessful() {
    "$@"
    while [ $? -ne 0 ]
    do
      echo Retrying...
      sleep 1
        "$@"
    done
}

CB_INIT_BUCKET_NAME=${CB_INIT_BUCKET_NAME-"bgch-cb-api"}
CB_INIT_DATA_PATH=${CB_INIT_DATA_PATH-"/opt/couchbase/var/lib/couchbase/data"}
CB_INIT_INDEX_PATH=${CB_INIT_INDEX_PATH-"/opt/couchbase/var/lib/couchbase/data"}
CB_INIT_USERNAME=${CB_INIT_USERNAME-"Administrator"}
CB_INIT_PASSWORD=${CB_INIT_PASSWORD-"password"}
TOTAL_MEM=$(free -m | grep Mem | awk '{ print $2 }')
let RAM_QUOTA=$TOTAL_MEM*80/100
CB_INIT_RAMSIZE=${CB_INIT_RAMSIZE-$RAM_QUOTA}
CB_INIT_BUCKET_SIZE=${CB_INIT_BUCKET_SIZE-"$CB_INIT_RAMSIZE"}
CB_INIT_BUCKET_ENABLEFLUSH=${CB_INIT_BUCKET_ENABLEFLUSH-"0"}
CB_INIT_BUCKET_REPLICA_COUNT=${CB_INIT_BUCKET_REPLICA_COUNT-"0"}
CB_SERVER_HOST=${CB_SERVER_HOST-"$COUCHBASE_SERVER_PORT_8091_TCP_ADDR"}
CB_SERVER_PORT=${CB_SERVER_PORT-"$COUCHBASE_SERVER_PORT_8091_TCP_PORT"}
CB_SERVER_ENDPOINT=${CB_SERVER_HOST}:${CB_SERVER_PORT}
ONESHOT=${false-"$ONESHOT"}

# if we have a bucket then everything's initialised already (flawed but it'll do for now)
env
echo "starting"
untilsuccessful /opt/couchbase/bin/couchbase-cli bucket-list -c $CB_SERVER_ENDPOINT \
  -u $CB_INIT_USERNAME -p $CB_INIT_PASSWORD | grep $CB_INIT_BUCKET_NAME

if [[ $? -ne 0 ]]; then

  export CB_REST_USERNAME=$CB_INIT_USERNAME
  export CB_REST_PASSWORD=$CB_INIT_PASSWORD

  echo "Initialising node"
  untilsuccessful /opt/couchbase/bin/couchbase-cli node-init -c $CB_SERVER_ENDPOINT \
      --node-init-data-path=$CB_INIT_DATA_PATH \
      --node-init-index-path=$CB_INIT_INDEX_PATH

  echo "Initialising cluster"
  untilsuccessful /opt/couchbase/bin/couchbase-cli cluster-init -c $CB_SERVER_ENDPOINT \
      --cluster-username=$CB_INIT_USERNAME \
      --cluster-password=$CB_INIT_PASSWORD \
      --cluster-ramsize=$CB_INIT_RAMSIZE

  echo "Creating bucket ${CB_INIT_BUCKET_NAME}"
  untilsuccessful /opt/couchbase/bin/couchbase-cli bucket-create -c $CB_SERVER_ENDPOINT \
      --user $CB_INIT_USERNAME \
      --password $CB_INIT_PASSWORD \
      --bucket=$CB_INIT_BUCKET_NAME \
      --bucket-ramsize=$CB_INIT_BUCKET_SIZE \
      --enable-flush=$CB_INIT_BUCKET_ENABLEFLUSH \
      --bucket-replica=${CB_INIT_BUCKET_REPLICA_COUNT}

  echo "Couchbase initialisation complete"
else
  echo "Couchbase already initialised"
fi
