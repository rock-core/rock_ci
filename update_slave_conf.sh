#! /bin/sh -ex

if test -z "DONE_SLAVE_CONF"; then
    cd /home/build/slave_conf
    git remote update
    git reset --hard origin/master
    export DONE_SLAVE_CONF=1
    exec $0
fi

cd /home/build/rock_admin_scripts
git remote update
git reset --hard origin/master
