#! /bin/sh -ex

SRC_DIR_WORKSPACE_PREFIX=/home/build/jenkins/workspace
SRC_DIR_FLAVOR_PREFIX=FLAVOR
SRC_DIR_SUFFIX=label/DebianUnstable

for workspace_name in $SRC_DIR_WORKSPACE_PREFIX/*; do
    if ! test -d $workspace_name/$SRC_DIR_FLAVOR_PREFIX; then
	continue
    fi

    for flavor in $workspace_name/$SRC_DIR_FLAVOR_PREFIX/*; do
	path=$flavor/$SRC_DIR_SUFFIX
	if ! test -f $path/dev/successful; then
	    echo "last build of `basename $workspace_name` seems to not have been successful. Skipping documentation generation"
	fi

	( rm -rf doc
	  cd $path/dev
	  . ./env.sh
	  gem install webgen coderay --no-rdoc --no-ri
	  rock-make-doc $PWD/../doc
	)
    done
done

