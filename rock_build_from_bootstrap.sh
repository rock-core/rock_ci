#! /bin/bash

set -ex

export PATH=/home/build/rock_admin_scripts/bin:$PATH
CONFIG_DIR=/home/build/slave_conf

job_basename=`dirname $JOB_NAME`
if test -f /home/build/$job_basename-$FLAVOR.yml; then
  $SHELL rock-build-server "$@" $CONFIG_DIR/$job_basename-$FLAVOR.yml
else
  $SHELL rock-build-server "$@" $CONFIG_DIR/default-$FLAVOR.yml
fi
touch dev/successful

