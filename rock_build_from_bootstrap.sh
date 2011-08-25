#! /bin/bash

set -ex

export PATH=/home/build/rock_admin_scripts/bin:$PATH

job_basename=`dirname $JOB_NAME`
if test -f /home/build/$job_basename-$FLAVOR.yml; then
  $SHELL rock-build-server "$@" /home/build/$job_basename-$FLAVOR.yml
else
  $SHELL rock-build-server "$@" /home/build/default-$FLAVOR.yml
fi
touch dev/successful

