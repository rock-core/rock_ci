#! /bin/sh -ex
#
# Script used in a separate jenkins job to update the scripts on each slave

sudo apt-get update
sudo apt-get -y install wget ruby rubygems doxygen

cd $JENKINS_HOME/build_scripts
git remote update
git reset --hard origin/master

