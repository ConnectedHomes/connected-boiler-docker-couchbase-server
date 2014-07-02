#!/bin/bash

gulp docker:run

IP=$(docker inspect --format='{{.NetworkSettings.IPAddress}}' $(docker ps -l -q))

COMMAND="curl --silent --connect-timeout=10 http://${IP}:8091/pools/default/buckets"
echo "Running: ${COMMAND}"
${COMMAND}
STATUS_CODE=$?

if [[ ${STATUS_CODE} -gt 0 ]]; then
    echo "Retrying ${COMMAND}"
    sleep 10
    ${COMMAND}
    STATUS_CODE=$?
fi

if [[ ${STATUS_CODE} -gt 0 ]]; then
    echo "Failed to curl couchbase"
fi

# stop last container
docker stop $(docker ps -l -q)

echo "docker ps | awk '{print $1}' | \xargs docker stop"

exit ${STATUS_CODE}
