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

if test "x$SKIP_SUCCESSFUL" = "xtrue" && test -d dev && test -f dev/successful; then
    echo "last build was successful and SKIP_SUCCESSFUL is set, doing nothing"
    exit 0
fi

do_incremental=1
do_full_cleanup=0
if test "x$INCREMENTAL" = "xtrue" || test "x$MODE" = "xincremental"; then
    echo "MODE=incremental, doing an incremental build"
elif test "x$MODE" = "xbootstrap"; then
    echo "MODE=bootstrap, doing a full build"
    do_incremental=0
    do_full_cleanup=1
elif test -d dev && ! test -f dev/successful; then
    echo "last build was unsuccessful, doing an incremental build"
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

if test "x$do_incremental" = "x0"; then
    if test "x$do_full_cleanup" = "x1"; then
        rm -rf dev
    elif test -d dev; then
        rm -rf dev/install
        find dev -type d -name build -exec rm -rf {} \; -prune
        rm -rf dev/.gems dev/autoproj
    fi
fi

$SHELL -ex rock-build-incremental "$@"  $configfile
touch dev/successful
mkdir -p logs
cp -r dev/install/log logs/`date +%F-%H%M%S`

if test "x$DOCGEN" = "xtrue"; then
    ( set -e
      cd dev
      . ./env.sh
      export PATH=/home/build/rock_admin_scripts/bin:$PATH
      export RUBYLIB=/home/build/rock_admin_scripts/lib:$RUBYLIB

      gem install hoe webgen coderay --no-rdoc --no-ri
      sudo apt-get install doxygen
      rm -rf $PWD/../doc
      rock-make-doc --status=master:next,next:stable $PWD/../doc "-b $FLAVOR git://gitorious.org/rock/doc.git"
    ) > docgen.txt 2>&1
    touch dev/doc-successful
fi

if test "x$CLEAN_IF_SUCCESSFUL" = "xtrue"; then
    touch dev/cleaned
    rm -rf dev/install

    find dev -type d -name build -exec rm -rf {} \; -prune
fi

