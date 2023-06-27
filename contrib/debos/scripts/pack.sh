#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace

kernel_out="$ARTIFACTDIR/$1.vmlinuz"
archive_out="$ARTIFACTDIR/$1.cpio.gz"

echo "moving kernel to ${kernel_out}"
cp "${ROOTDIR}"/boot/vmlinuz-* "${kernel_out}"
rm -f "${ROOTDIR}"/boot/vmlinuz-*

echo "creating ${archive_out} ..."
cd "${ROOTDIR}" || exit 1
find . -print0 | cpio --reproducible -0 -o -H newc | gzip -9 -n > "${archive_out}"

trap - EXIT
