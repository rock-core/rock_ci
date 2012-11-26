VM_NAME=$1
CONFIG_NAME=$2
FLAVOR=$3
shift 3

if test "x$1" = "xskip"; then
    skip=1
    shift
fi

if test -n "$1"; then
    ROCK_BOOTSTRAP_BRANCH=$1
    shift
fi

logfile=logs/$VM_NAME-$CONFIG_NAME-$FLAVOR.txt
if test -n "$skip"; then
    if test -f $logfile-SUCCESS; then
        echo "skipping $VM_NAME $CONFIG_NAME $FLAVOR"
        continue
    fi
fi

echo "building $VM_NAME $CONFIG_NAME $FLAVOR"
vagrant destroy -f
vagrant up $VM_NAME

while true; do
    vagrant ssh $VM_NAME -c "$@ RUBY=ruby CONFIG_NAME=$CONFIG_NAME FLAVOR=$FLAVOR BUILDCONF_BRANCH=$ROCK_BOOTSTRAP_BRANCH PATH=/admin_scripts/bin:\$PATH /build_scripts/rock_build.sh git://gitorious.org/rock/buildconf-all.git" >> $logfile

    retry=0
    if grep -q -i "segmentation fault" $logfile; then
        echo "got segmentation fault during compilation, retrying"
        retry=1
    elif grep -q -i "internal compiler error" $logfile; then
        echo "got ICE, retrying"
        retry=1
    fi
    if test "x$retry" != "x1"; then
        break
    fi
done

rm -rf vm_logs/$VM_NAME-$CONFIG_NAME-$FLAVOR
vagrant ssh $VM_NAME -c "cp -r dev/install/logs /vm_logs/$VM_NAME-$CONFIG_NAME-$FLAVOR"

rm -f $logfile-SUCCESS $logfile-FAILURE
if grep -q "Build finished successfully" $logfile; then
    mv $logfile $logfile-SUCCESS
else
    mv $logfile $logfile-FAILURE
fi

exit_code=$?
vagrant destroy -f

exit $exit_code

# vim:tw=0

