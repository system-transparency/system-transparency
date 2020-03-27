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
root="$(cd "${dir}/../../" && pwd)"

mnt="/tmp/mnt_stimg"
img="${dir}/Syslinux_Linuxboot.img"

mkdir -p "${mnt}_boot" || { echo -e "mkdir $failed"; exit 1; }
# offset: sfdisk -d ${img}
# ...
# deploy/mixed-firmware/Syslinux_Linuxboot.img1 : start=        2048, size=       24576, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, uuid=B48F8501-978A-F644-9509-7D1146C867"
# deploy/mixed-firmware/Syslinux_Linuxboot.img2 : start=       26624, size=       14303, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, uuid=0CC2C552-FACE-4745-B9F2-B90257BBD6"
#
# 1st partition:
# 2048 blocks * 512 bytes per block -> 1048576 
mount -o loop,offset=1048576 "${img}" "${mnt}_boot" || { echo -e "mount 1st partition $failed"; exit 1; }
echo "[INFO]: mounted 1st partition of $(realpath --relative-to=${root} ${img}) at ${mnt}_boot"