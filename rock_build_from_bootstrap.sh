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
rm -rf api

if test "x$do_incremental" = "x0"; then
    if test "x$do_full_cleanup" = "x1"; then
        rm -rf dev
    elif test -d dev; then
        rm -rf dev/install
        find dev -type d -name build -exec rm -rf {} \; -prune
        rm -rf dev/.gems dev/autoproj
    fi
fi

# Always delete autoproj's configuration directory so that we always start fresh
# Otherwise, it would not get updated
rm -rf dev/autoproj
$SHELL -ex rock-build-incremental "$@"  $configfile
touch dev/successful

if test "x$DOCGEN" = "xtrue"; then
    api_dir=$PWD/api
    # Only generate the documentation from autoproj. The complete documentation
    # is generated by a separate build target
    ( 
      cd dev
      . ./env.sh

      gem install hoe coderay rdoc webgen --no-rdoc --no-ri
      sudo apt-get install doxygen
      gem rdoc autoproj
      gem rdoc autobuild

      echo "generating the API documentation from the autoproj packages"
      autoproj doc
      echo "copying API documentation to $api_dir"
      cp -r install/doc $api_dir
      
      autoproj_version=`$GEM_HOME/bin/autoproj --version | sed 's/autoproj.*v//'`
      autoproj_api_dir=$GEM_HOME/doc/autoproj-$autoproj_version
      if test -d $autoproj_api_dir; then
          echo "copying autoproj API documentation to $api_dir/autoproj"
          cp -r $autoproj_api_dir/rdoc $api_dir/autoproj
      else
          echo "could not find the autoproj API in $autoproj_api_dir"
      fi
      
      autobuild_version=`$GEM_HOME/bin/autobuild --version | sed 's/autobuild.*v//'`
      autobuild_api_dir=$GEM_HOME/doc/autobuild-$autobuild_version
      if test -d $autobuild_api_dir; then
          echo "copying autobuild API documentation to $api_dir/autobuild"
          cp -r $autobuild_api_dir/rdoc $api_dir/autobuild
      else
          echo "could not find the autobuild API in $autobuild_api_dir"
      fi
    ) > docgen.txt 2>&1
    touch dev/doc-successful
fi

# Save the logs AFTER documentation generation, so that they include docgen logs
# as well
mkdir -p logs
cp -r dev/install/log logs/`date +%F-%H%M%S`

if test "x$CLEAN_IF_SUCCESSFUL" = "xtrue"; then
    touch dev/cleaned

    rm -rf archive_cache
    mv dev/install/cache archive_cache
    rm -rf dev/install
    find dev -type d -name build -exec rm -rf {} \; -prune

    mkdir -p dev/install
    mv archive_cache dev/install
fi

