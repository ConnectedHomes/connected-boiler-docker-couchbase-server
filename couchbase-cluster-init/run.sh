#!/bin/bash

# error on unset variable
set -o nounset
# error on clobber
set -o noclobber

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
GATEWAY=$(netstat -rn | grep '^0.0.0.0' | awk '{ print $2 }')
export ETCDCTL_PEERS=${ETCDCTL_PEERS:-"$GATEWAY:4001"}
echo "Setting etcd peers to $ETCDCTL_PEERS"
CB_SERVER_HOST=${CB_SERVER_HOST-"$COUCHBASE_PORT_8091_TCP_ADDR"}
CB_SERVER_PORT=${CB_SERVER_PORT-"$COUCHBASE_PORT_8091_TCP_PORT"}
CB_SERVER_ENDPOINT=${CB_SERVER_HOST}:${CB_SERVER_PORT}

waitForNodeToStart() {
  CMD="wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 0 ${CB_SERVER_ENDPOINT} -o /dev/null"
  echo running "$CMD"
  `$CMD`
  [[ "$?" = 0 ]] && assignEC2Hostname

  echo "Error: couldn't connect to node"
  exit 1
}

assignEC2Hostname() {
  EC2_HOSTNAME=$(curl -sS http://169.254.169.254/latest/meta-data/public-hostname --connect-timeout 5)
  if [[ $? = 0 ]]; then 
    echo "We're on EC2; assigning hostname '${EC2_HOSTNAME}' to node"
    CMD="curl --retry 10 -s http://$CB_SERVER_HOST:$CB_SERVER_PORT/node/controller/rename \
      -d hostname=${EC2_HOSTNAME} -XPOST"
    echo running "$CMD"
    eval $CMD
    # and address the node using the ec2 hostname from now on
    CB_SERVER_HOST=${EC2_HOSTNAME}
    CB_SERVER_ENDPOINT=${CB_SERVER_HOST}:${CB_SERVER_PORT}
  fi

  chkCluster
}

chkCluster() {
  CMD="curl --retry 5 -s http://${CB_SERVER_ENDPOINT}/pools/default --output /dev/null --write-out %{http_code}"
  echo running "$CMD"
  HTTP_RESP_CODE=`$CMD`
  [[ "$HTTP_RESP_CODE" = 404 ]] && createOrJoinCluster
  [[ "$HTTP_RESP_CODE" = 200 ]] && alreadyCluster
  # prompting for creds, so consider it 'clusterified'
  [[ "$HTTP_RESP_CODE" = 401 ]] && alreadyCluster
}

createOrJoinCluster() {
  CMD="etcdctl mk /couchbase-cluster/leader ${CB_SERVER_ENDPOINT}"
  echo running "$CMD"
  eval $CMD
  RET_CODE=$?

  # /couchbase-cluster/leader was unset; create cluster
  [[ $RET_CODE = 0 ]] && createCluster
  # /couchbase-cluster/leader was already set; join cluster
  [[ $RET_CODE = 4 ]] && joinCluster

  [[ $RET_CODE -ne 0 ]] && exit $RET_CODE
}

joinCluster() {
  EXISTING_MEMBER=$(etcdctl get /couchbase-cluster/leader)

  CMD="/opt/couchbase/bin/couchbase-cli rebalance -c ${EXISTING_MEMBER} \
    --server-add ${CB_SERVER_ENDPOINT} \
    --server-add-username=$CB_INIT_USERNAME \
    --server-add-password=$CB_INIT_PASSWORD \
    --user $CB_INIT_USERNAME \
    --password $CB_INIT_PASSWORD"
  echo running "$CMD"
  eval $CMD
  RET_CODE=$?
  [[ $RET_CODE = 0 ]] && joinedCluster

  echo "Bad exit code: $RET_CODE"
  exit $RET_CODE 
}

createCluster() {
  CMD="curl --retry 5 -s http://${CB_SERVER_ENDPOINT}/settings/web \
    --output /dev/null --write-out %{http_code} -XPOST \
    -d username=$CB_INIT_USERNAME \
    -d password=$CB_INIT_PASSWORD \
    -d port=8091"
  echo running "$CMD"
  HTTP_RESP_CODE=`$CMD`
  [[ "$HTTP_RESP_CODE" = 200 ]] && setMemoryQuota

  echo "Bad response code: $HTTP_RESP_CODE"
  exit 1
}

setMemoryQuota() {
  CMD="curl --retry 5 -s http://${CB_SERVER_ENDPOINT}/pools/default \
    --output /dev/null --write-out %{http_code} -XPOST \
    -d memoryQuota=$CB_INIT_RAMSIZE \
    -u $CB_INIT_USERNAME:$CB_INIT_PASSWORD"
  echo running "$CMD"
  HTTP_RESP_CODE=`$CMD`
  [[ "$HTTP_RESP_CODE" = 200 ]] && createBucket

  echo "Bad response code: $HTTP_RESP_CODE"
  exit 1
}

createBucket() {
  CMD="curl --retry 5 -s http://${CB_SERVER_ENDPOINT}/pools/default/buckets \
    --output /dev/null --write-out %{http_code} -XPOST \
    -d authType=sasl \
    -d name=$CB_INIT_BUCKET_NAME \
    -d bucketType=couchbase \
    -d flushEnabled=$CB_INIT_BUCKET_ENABLEFLUSH \
    -d ramQuotaMB=$CB_INIT_BUCKET_SIZE \
    -d replicaNumber=$CB_INIT_BUCKET_REPLICA_COUNT \
    -u $CB_INIT_USERNAME:$CB_INIT_PASSWORD"
  echo running "$CMD"
  HTTP_RESP_CODE=`$CMD`
  [[ "$HTTP_RESP_CODE" = 202 ]] && createdBucket
  [[ "$HTTP_RESP_CODE" = 204 ]] && bucketAlreadyExists

  echo "Bad response code: $HTTP_RESP_CODE"
  exit 1
}

alreadyCluster() {
  echo "Already a cluster; doing nothing"
  exit 0
}

joinedCluster() {
  echo "Joined cluster"
  exit 0
}

createdBucket() {
  echo "Created cluster and bucket"
  exit 0
}

bucketAlreadyExists() {
  echo "Bucket exists already!"
  exit 0
}

waitForNodeToStart
