#! /bin/bash

set -ex

export PATH=/home/build/rock_admin_scripts/bin:$PATH
CONFIG_DIR=/home/build/slave_conf

job_basename=`dirname $JOB_NAME`
if test -f $CONFIG_DIR/$job_basename-$FLAVOR.yml; then
  configfile=$CONFIG_DIR/$job_basename-$FLAVOR.yml
else
  configfile=$CONFIG_DIR/default-$FLAVOR.yml
fi

if test -d dev && test -f dev/successful; then
  echo "last build was successful, doing a full build"
  $SHELL -ex rock-build-server "$@"  $configfile
else
  echo "last build was unsuccessful, doing an incremental build"
  $SHELL -ex rock-build-incremental "$@"  $configfile
fi

touch dev/successful

