#! /bin/bash

set -x

export CCACHE_DISABLE=1
SRC_DIR_WORKSPACE_PREFIX=/home/build/jenkins/workspace
SRC_DIR_FLAVOR_PREFIX=FLAVOR
SRC_DIR_SUFFIX=label/DebianUnstable
LOG_DIR=/home/build/logs
root_dir=$PWD

mkdir -p $LOG_DIR
result=0
for workspace_dir in $SRC_DIR_WORKSPACE_PREFIX/*; do
    workspace_name=`basename $workspace_dir`
    if ! test -d $workspace_dir/$SRC_DIR_FLAVOR_PREFIX; then
        continue
    fi

    available_flavors=""
    candidates=`echo $workspace_dir/$SRC_DIR_FLAVOR_PREFIX/* | sort`
    for flavor_dir in $candidates; do
        if test -d $flavor_dir/$SRC_DIR_SUFFIX/dev; then
            flavor_name=`basename $flavor_dir`
            if test -z "$available_flavors"; then
                available_flavors="$flavor_name"
            else
                available_flavors="$available_flavors,$flavor_name"
            fi
        fi
    done
    echo "available flavors: $available_flavors"

    for flavor_dir in $workspace_dir/$SRC_DIR_FLAVOR_PREFIX/*; do
	echo
	flavor_name=`basename $flavor_dir`
	path=$flavor_dir/$SRC_DIR_SUFFIX
	if ! test -f $path/dev/doc-successful; then
	    echo "last build of $workspace_name:$flavor_name did not generate documentation, skipping"
	    continue
	fi

        set +e
        if test "x$FORCE_DOC_GEN" = "xtrue"; then
            rm -f $path/docgen.stamp
        fi

	if test -f $path/docgen.stamp && test $path/docgen.stamp -nt $path/dev/doc-successful; then
	    echo "build of $workspace_name:$flavor_name did not get updated since last time. Skipping ..."
	    continue
	fi

	echo "generating documentation for $workspace_name:$flavor_name"
        rm -rf $path/doc
        mkdir $path/doc
        cp -r $path/api $path/doc
        if test -d archive_cache; then
            mkdir -p dev/install/cache
            rsync -a archive_cache/ dev/install/cache/
        fi

	( set -e
	  cd $path/dev
          # Source here the environment of the flavor-corresponding rock bootstrap - which should be NOT cleaned after 
          # a successful build, since typelib and other components will be required for the call to rock-directory-pages 
          if test $workspace_name = "RockBootstrap19"; then
              ref_install_root=/home/build/jenkins/workspace/RockBootstrap19/FLAVOR/$flavor_name/label/DebianUnstable/dev/
          else
              ref_install_root=/home/build/jenkins/workspace/RockIncremental/FLAVOR/$flavor_name/label/DebianUnstable/dev/
          fi
          # Install admin_scripts
          source $ref_install_root/env.sh
          ( cd $ref_install_root
              aup base/admin_scripts
              aup base/doc )
          # Trick autoproj to think that we're setup for the current directory
          export AUTOPROJ_ROOT_DIR=$PWD
          export GEM_HOME=$PWD/.gems
          # admin_scripts is not part of the layout, it is therefore not
          # included in env.sh. Add it to our environment
          export PATH=$ref_install_root/base/admin_scripts/bin:$GEM_HOME/bin:$PATH
          export RUBYLIB=$ref_install_root/base/admin_scripts/lib:$RUBYLIB

	  gem install webgen coderay --no-rdoc --no-ri

          tempdir=$(mktemp -d)
          echo "creating rock's main documentation in $tempdir/main"
          git clone $ref_install_root/base/doc $tempdir

          cd $path/dev
          if test "$flavor_name" = "master"; then
              rock-directory-pages --status=master:next "$tempdir/main/src" $path/doc/api
          elif test "$flavor_name" = "next"; then
              rock-directory-pages --status=next:stable "$tempdir/main/src" $path/doc/api
          else
              rock-directory-pages "$tempdir/main/src" $path/doc/api
          fi

          cd $tempdir/main
          webgen --version
          ROCK_DOC_FLAVORED=$flavor_name:$available_flavors webgen
          echo "moving main documentation in $path/doc"
          mv out/* $path/doc

          echo "deleting $tempdir"
          rm -rf $tempdir
	) >> $path/docgen.txt 2>&1
	if test "$?" -ne "0"; then
	    echo "generation failed for $workspace_name:$flavor_name"
	    echo "log in $workspace_name-$flavor_name.txt"
	    result=1
	else
	    touch $path/docgen.stamp
	fi
        cp $path/docgen.txt $workspace_name-$flavor_name.txt
	set -e
    done
done
echo "Result of document generation"
exit $result

