#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

failed="\e[1;5;31mfailed\e[0m"

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mnt="/tmp/mnt_stimg"
img="${dir}/MBR_Syslinux_Linuxboot.img"

mkdir -p ${mnt} || { echo -e "mkdir $failed"; exit 1; }
# offset: sfdisk -d ${img}
# ...
# deploy/mixed-firmware/MBR_Syslinux_Linuxboot.img1 : start=        2048, size=      407552, type=83, bootable
#
# 2048 blocks * 512 bytes per block -> 1048576  
mount -o loop,offset=1048576 ${img} ${mnt} || { echo -e "mount $failed"; exit 1; }
echo "[INFO]: mounted ${img} at ${mnt}"
