#!/bin/bash

set -o errexit
set -o nounset

export NODE_ENV=test
declare -r DIR=$(cd "$(dirname "$0")" && pwd)
source "$DIR/../../node_modules/connected-boiler-shared/_test_helper.sh"

gulp docker:run

LAST_IMAGE=$(docker ps -l -q)
stopMe() {
  echo Trap CB stop;
  docker stop $LAST_IMAGE || true
}
addTrap stopMe EXIT SIGINT SIGTERM

echo "Last image: $LAST_IMAGE"
docker port ${LAST_IMAGE} 8091
API_HOST=$(docker port ${LAST_IMAGE} 8091)

if [[ ${DOCKER_HOST:-} != '' ]]; then
 IP=$(echo ${DOCKER_HOST} | sed -e 's#.*//##g' -e 's#:.*##g')
 PORT=$(echo $API_HOST | sed 's/.*://g')
 API_HOST=${IP}:${PORT}
fi

sleep 15

docker logs ${LAST_IMAGE}

COMMAND="curl --silent --connect-timeout 3 http://${API_HOST}/pools/default/buckets"
echo "Running: ${COMMAND}"

EXIT_CODE=0
if ! ${COMMAND}; then
    EXIT_CODE=1
    echo "curl failed. Sleeping before retry"
    sleep 10

    docker logs ${LAST_IMAGE}
    echo "Retrying ${COMMAND}"

    if ! ${COMMAND}; then
      echo "Failed to curl couchbase"
    else
      EXIT_CODE=0
    fi
fi

stopMe
exit ${EXIT_CODE}