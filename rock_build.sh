#! /bin/bash
#
# Main build script in all build server jobs
#
# The script assumes that the job is located in a directory whose first element
# is the job name (it is the case when using jenkins)
#
# Control environment variables:
#
#   SKIP_SUCCESSFUL: if set to true, any build show last result was successful
#                    is ignored. The default is false.
#   MODE:
#       full-bootstrap: remove the complete dev/ directory and bootstrap fresh
#       bootstrap: keep the currently checked out code in dev/. Just delete all
#                  build byproducts, gems and autoproj configuration
#       incremental: builds from the current state of dev/. If the build has
#                    been cleaned last time, the job is ignored
#       auto: do a bootstrap if dev/ is clean and otherwise do an incremental
#             build
#
#   DOCGEN: if set to true, the API documentation is generated
#   CLEAN_IF_SUCCESSFUL: remove all build byproducts if the build finishes
#                        successfully (useful to keep disk usage low)

set -ex

CONFIG_DIR=$(dirname $0)
job_name=default
job_type=master
if test -n "$CONFIG_NAME"; then
    job_name=$CONFIG_NAME
elif test -n "$JOB_NAME"; then
    job_basename=`dirname $JOB_NAME`
fi
if test -n "$FLAVOR"; then
    job_type=$FLAVOR
fi

if test -f $CONFIG_DIR/$job_name-$job_type.config; then
  . $CONFIG_DIR/$job_name-$job_type.config
elif test -f $CONFIG_DIR/default-$job_type.config; then
  . $CONFIG_DIR/default-$job_type.config
fi

if test -f $CONFIG_DIR/$job_name-$job_type.yml; then
  configfile=$CONFIG_DIR/$job_name-$job_type.yml
else
  configfile=$CONFIG_DIR/default-$job_type.yml
fi

if test "x$SKIP_SUCCESSFUL" = "xtrue" && test -d dev && test -f dev/successful; then
    echo "last build was successful and SKIP_SUCCESSFUL is set, doing nothing"
    exit 0
fi

if test -z "$MODE"; then
    MODE=auto
fi

do_incremental=1
do_full_cleanup=0
if test "x$INCREMENTAL" = "xtrue" || test "x$MODE" = "xincremental"; then
    echo "MODE=incremental, doing an incremental build"
elif test "x$MODE" = "xfull-bootstrap"; then
    echo "MODE=full-bootstrap, doing a full build, including checking out packages"
    do_incremental=0
    do_full_cleanup=1
elif test "x$MODE" = "xbootstrap"; then
    echo "MODE=bootstrap, doing a full build but not checking out packages again. Use full-bootstrap for that"
    do_incremental=0
    do_full_cleanup=0
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

# If the current dev/install folder has a cache of the downloaded archives, then
# save it
if test -d dev/install/cache; then
    mkdir -p archive_cache
    rsync -a dev/install/cache/ archive_cache/
fi

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
rm -rf dev/autoproj dev/.remotes

# If there is an archive cache, copy it into our working directory
if test -d archive_cache; then
    mkdir -p dev/install/cache
    rsync -a archive_cache/ dev/install/cache/
fi

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
      rsync -a --delete install/doc/ $api_dir/
      
      autoproj_version=`$GEM_HOME/bin/autoproj --version | sed 's/autoproj.*v//'`
      autoproj_api_dir=$GEM_HOME/doc/autoproj-$autoproj_version
      if test -d $autoproj_api_dir; then
          echo "copying autoproj API documentation to $api_dir/autoproj"
          rsync -a --delete $autoproj_api_dir/rdoc/ $api_dir/autoproj/
      else
          echo "could not find the autoproj API in $autoproj_api_dir"
      fi
      
      autobuild_version=`$GEM_HOME/bin/autobuild --version | sed 's/autobuild.*v//'`
      autobuild_api_dir=$GEM_HOME/doc/autobuild-$autobuild_version
      if test -d $autobuild_api_dir; then
          echo "copying autobuild API documentation to $api_dir/autobuild"
          rsync -a $autobuild_api_dir/rdoc/ $api_dir/autobuild/
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

    if test -d dev/install/cache; then
        mkdir -p archive_cache
        rsync -a dev/install/cache/ archive_cache/
    fi
    rm -rf dev/install
    find dev -type d -name build -exec rm -rf {} \; -prune
    if test -d archive_cache; then
        mkdir -p dev/install/cache
        rsync -a archive_cache/ dev/install/cache/
    fi
fi

