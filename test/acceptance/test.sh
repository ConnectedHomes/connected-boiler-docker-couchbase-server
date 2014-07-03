#!/bin/bash

set -o errexit
set -o nounset


gulp docker:run

LAST_IMAGE=$(docker ps -l -q)
trap "docker stop $LAST_IMAGE" EXIT SIGINT SIGTERM


if [[ ${DOCKER_HOST:-} != '' ]]; then
 IP=$(echo ${DOCKER_HOST} | sed -e 's#.*//##g' -e 's#:.*##g')
else
 IP=$(docker inspect --format='{{.NetworkSettings.IPAddress}}' ${LAST_IMAGE})
fi

sleep 12

docker logs ${LAST_IMAGE}

COMMAND="curl --silent --connect-timeout 3 http://${IP}:8091/pools/default/buckets"
echo "Running: ${COMMAND}"

EXIT_CODE=0
if ! ${COMMAND}; then
    echo "curl failed. Sleeping before retry"
    sleep 10

    docker logs ${LAST_IMAGE}
    echo "Retrying ${COMMAND}"

    if ! ${COMMAND}; then
      echo "Failed to curl couchbase"
    fi
    EXIT_CODE=1
fi

echo "docker ps | awk '{print \$1}' | \xargs docker stop"

exit ${EXIT_CODE}
