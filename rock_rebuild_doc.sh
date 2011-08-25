#! /bin/bash -ex

( cd /home/build/rock_admin_scripts
  git pull )

for flavor in master next stable; do
  path=/home/build/jenkins/workspace/RockBootstrap/FLAVOR/$flavor/label/DebianUnstable
  if test -d $path/doc; then
    ( set -ex
      cd $path/dev
      . ./env.sh
      which rock-make-doc
      rm -rf $PWD/../doc
      rock-make-doc $PWD/../doc
    )
  else
    echo "not rebuilding documentation for flavor $flavor, the last build failed"
  fi
done

