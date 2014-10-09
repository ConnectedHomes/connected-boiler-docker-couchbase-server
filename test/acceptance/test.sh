#!/bin/bash

set -o errexit
set -o nounset

EXPECTED_SERVICES='\(couchbase\)'

declare -r DIR=$(cd "$(dirname "$0")" && pwd)
source "$DIR/../../node_modules/connected-boiler-shared/_test_helper.sh"

# generate config file from fig.yml
#
FIG_FILE=fig.yml
FIG_TEST_FILE=fig-test.yml
cp $FIG_FILE $FIG_TEST_FILE

CB_INIT_BUCKET_NAME=testing-testing-bucket

setEnvironmentVar "CB_INIT_BUCKET_NAME" ${CB_INIT_BUCKET_NAME} ${FIG_TEST_FILE}
setEnvironmentVar "NODE_ENV" "test" ${FIG_TEST_FILE}
setEnvironmentVar "BGCH_CBAPI_DBNAME" ${CB_INIT_BUCKET_NAME} ${FIG_TEST_FILE}

stopMe() {
  echo Trap CB stop;
  figStop
}
addTrap stopMe EXIT SIGINT SIGTERM

# invocation
#
[[ $(countRunningServices) = 1 && ${CB_ALLOW_EXISTING_FIG:-} = '1' ]] || {
  figStop
  figRm
  figPull
  #figPull $(getCouchbaseControlImageEndpoint)

  figBuild

  figUp &
  trapFigStop

  waitForRunningServicesCount 1
}

COMMAND="curl --silent --connect-timeout 3 http://$(getDockerIp):8091/pools/default/buckets"
echo "Running: ${COMMAND}"

EXIT_CODE=0
if ! ${COMMAND}; then
    EXIT_CODE=1
    echo "curl failed. Sleeping before retry"
    sleep 10

    echo "Retrying ${COMMAND}"

    if ! ${COMMAND}; then
      echo "Failed to curl couchbase"
    else
      EXIT_CODE=0
    fi
fi

stopMe
exit ${EXIT_CODE}
