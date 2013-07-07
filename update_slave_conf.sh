#! /bin/sh -ex
#
# Script used in a separate jenkins job to update the scripts on each slave

sudo apt-get update
sudo apt-get -y install wget ruby rubygems doxygen

if test -z "$DONE_SLAVE_CONF"; then
    cd /home/build/slave_conf
    git remote update
    git reset --hard origin/master
    export DONE_SLAVE_CONF=1
    exec $0
fi

if test -d /home/build/rock_buildconf; then
    cd /home/build/rock_buildconf
    git remote update
    git reset --hard origin/master
else
    git clone git://gitorious.org/rock/buildconf-all.git /home/build/rock_buildconf
fi

if test -d /home/build/rock_admin_scripts; then
    cd /home/build/rock_admin_scripts
    git remote update
    git reset --hard origin/master
else
    git clone git://gitorious.org/rock/admin_scripts.git /home/build/admin_scripts
fi
