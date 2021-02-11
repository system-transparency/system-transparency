#!/bin/bash

set -o errexit
set -o nounset
# set -o xtrace

kernel_out="$ARTIFACTDIR/$1.vmlinuz"
archive_out="$ARTIFACTDIR/$1.cpio.gz"

if [ -z "$SOURCE_DATE_EPOCH" ] ; then
  echo "Environment SOURCE_DATE_EPOCH is not set!" >&2
  exit 1
fi

echo "set date of files to SOURCE_DATE_EPOCH"
touch -hcd "@$SOURCE_DATE_EPOCH" "${ROOTDIR}/boot/vmlinuz-"*
find ${ROOTDIR} | while read -r line ; do touch -hcd "@$SOURCE_DATE_EPOCH" "$line" ; done

echo "moving kernel to ${kernel_out}"
mv "${ROOTDIR}/boot/vmlinuz-"* "${kernel_out}"

echo "creating ${archive_out} ..."
find ${ROOTDIR} -print0 | cpio --reproducible -0 -o -H newc | gzip -9 -n > "${archive_out}"

trap - EXIT
