#!/bin/bash -x

TMPD=$(mktemp -d /tmp/$0-XXXXXXX)
trap "rm -rf $TMPD" EXIT

pushd $TMPD
curl --output package.rpm -L "$2"
rpm2cpio package.rpm | cpio -idmv
find .
popd

cp "$TMPD/$1" work/
