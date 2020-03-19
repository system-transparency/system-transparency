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
img="${dir}/Syslinux_Linuxboot.img"

mkdir -p "${mnt}p1" || { echo -e "mkdir $failed"; exit 1; }
mkdir -p "${mnt}p2" || { echo -e "mkdir $failed"; exit 1; }
# offset: sfdisk -d ${img}
# ...
# deploy/mixed-firmware/MBR_Syslinux_Linuxboot.img1 : start=        2048, size=       40960, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, uuid=671EE130-82A5-9C45-9C20-8963039DEBD4, name="STBOOT", attrs="LegacyBIOSBo"
# deploy/mixed-firmware/MBR_Syslinux_Linuxboot.img2 : start=       43008, size=      366559, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, uuid=BDB5C1C2-7BD7-E94A-BE80-F6257250F2B8, name="STDATA"
#
# 2048 blocks * 512 bytes per block -> 1048576 
# 43008 blocks * 512 bytes per block -> 22020096 
mount -o loop,offset=1048576 "${img}" "${mnt}p1" || { echo -e "mount 1st partition $failed"; exit 1; }
echo "[INFO]: mounted 1st partition of ${img} at ${mnt}p1"
mount -o loop,offset=22020096 "${img}" "${mnt}p2" || { echo -e "mount 2nd partition $failed"; exit 1; }
echo "[INFO]: mounted 1st partition of ${img} at ${mnt}p2"
