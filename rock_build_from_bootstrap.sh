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

do_incremental=1
if test "x$INCREMENTAL" = "xtrue"; then
    echo "INCREMENTAL is set, doing an incremental build"
elif test -d dev && ! test -f dev/successful; then
    echo "last build was unsuccessful, doing an incremental build"
elif test "x$SKIP_SUCCESSFUL" = "xtrue" && test -d dev && test -f dev/successful; then
    echo "last build was successful and SKIP_SUCCESSFUL is set, doing nothing"
    exit 0
else
    echo "doing a full build"
    do_incremental=0
fi

if test "x$do_incremental" = "x1" && test -f dev/cleaned; then
    echo "this is an incremental build, but the last build got cleaned, doing nothing"
    exit 0
fi

rm -f dev/successful
rm -f dev/doc-successful
rm -f dev/cleaned
rm -f docgen.txt
if test "x$do_incremental" = "x1"; then
  $SHELL -ex rock-build-incremental "$@"  $configfile
else
  $SHELL -ex rock-build-server "$@"  $configfile
fi
touch dev/successful
mkdir -p logs
cp -r dev/install/log logs/`date +%F-%H%M%S`

if test "x$DOCGEN" = "xtrue"; then
    ( set -e
      cd dev
      . ./env.sh
      export PATH=/home/build/rock_admin_scripts/bin:$PATH
      export RUBYLIB=/home/build/rock_admin_scripts/lib:$RUBYLIB

      gem install webgen coderay --no-rdoc --no-ri
      sudo apt-get install doxygen
      rm -rf doc
      rock-make-doc --status=master:next,next:stable $PWD/../doc
    ) 2>&1 | tee docgen.txt
    touch dev/doc-successful
fi

if test "x$CLEAN_IF_SUCCESSFUL" = "xtrue"; then
    touch dev/cleaned
    rm -rf dev/install

    find dev -type d -name build -exec rm -rf {} \; -prune
fi

