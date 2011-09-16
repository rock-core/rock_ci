#! /bin/sh -ex

cd /home/build/rock_admin_scripts
git remote update
git reset --hard origin/master
cd /home/build/slave_conf
git remote update
git reset --hard origin/master
