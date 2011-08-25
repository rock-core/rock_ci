#! /bin/bash

set -ex

OLD_PATH=$PWD
cd /home/build/rock_admin_scripts
git pull
cd $OLD_PATH

export PATH=/home/build/rock_admin_scripts/bin:$PATH

job_basename=`dirname $JOB_NAME`
if test -f /home/build/$job_basename-$FLAVOR.yml; then
  $SHELL rock-build-incremental "$@" /home/build/$job_basename-$FLAVOR.yml
else
  $SHELL rock-build-incremental "$@" /home/build/default-$FLAVOR.yml
fi

