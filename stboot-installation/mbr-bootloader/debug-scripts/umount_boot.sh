#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

mnt="/tmp/mnt_stimg"
echo "[INFO]: unmounting ${mnt})"
umount "${mnt}_boot"
rm -r -f "${mnt}_boot"

trap - EXIT