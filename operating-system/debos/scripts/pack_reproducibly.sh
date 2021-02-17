#!/bin/bash

set -o errexit
set -o nounset
# set -o xtrace

kernel_out="$ARTIFACTDIR/$1.vmlinuz"
archive_out="$ARTIFACTDIR/$1.cpio.gz"

echo "set date of files to SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH"
touch -hcd "@$SOURCE_DATE_EPOCH" "${ROOTDIR}/boot/vmlinuz-"*
find ${ROOTDIR} | while read -r line ; do touch -hcd "@$SOURCE_DATE_EPOCH" "$line" ; done

echo "moving kernel to ${kernel_out}"
cp "root/boot/vmlinuz-"* "${kernel_out}"
rm -f "root/boot/vmlinuz-"*

echo "creating ${archive_out} ..."
cd ${ROOTDIR} || exit 1
find . -print0 | cpio --reproducible -0 -o -H newc | gzip -9 -n > "${archive_out}"

trap - EXIT
