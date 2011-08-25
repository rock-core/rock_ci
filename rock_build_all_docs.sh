#! /bin/bash

SRC_DIR_WORKSPACE_PREFIX=/home/build/jenkins/workspace
SRC_DIR_FLAVOR_PREFIX=FLAVOR
SRC_DIR_SUFFIX=label/DebianUnstable
LOG_DIR=/home/build/logs

mkdir -p $LOG_DIR
result=0
for workspace_dir in $SRC_DIR_WORKSPACE_PREFIX/*; do
    workspace_name=`basename $workspace_dir`
    if ! test -d $workspace_dir/$SRC_DIR_FLAVOR_PREFIX; then
        continue
    fi

    for flavor_dir in $workspace_dir/$SRC_DIR_FLAVOR_PREFIX/*; do
	flavor_name=`basename $flavor_dir`
	path=$flavor_dir/$SRC_DIR_SUFFIX
	if ! test -f $path/dev/successful; then
	    echo "last build of $workspace_name:$flavor_name seems to not have been successful. Skipping documentation generation"
	    continue
	fi

        set +e
	echo "generating documentation for $workspace_name:$flavor_name"
	( set -e
          rm -rf $path/doc
	  cd $path/dev
	  . ./env.sh
	  gem install webgen coderay --no-rdoc --no-ri
	  rock-make-doc $PWD/../doc
	) > ../docgen.txt 2>&1
	if test "$?" -ne "0"; then
	    echo "generation failed for $workspace_name:$flavor_name"
	    echo "log in $path/docgen.txt"
	    result=1
	fi
	set -e
    done
done
exit 1

