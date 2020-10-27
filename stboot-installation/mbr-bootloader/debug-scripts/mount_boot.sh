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
img="${dir}/../stboot_mbr_installation.img"

mkdir -p "${mnt}_boot" || { echo -e "mkdir $failed"; exit 1; }
# offset: sfdisk -d ${img}
# ...
# stboot_mbr_installation.img1 : start=        2048, size=       24577, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, uuid=AA42752A-0BC3-4948-BA85-284313A49965, name="STBOOT", attrs="LegacyBIOSBootable"
# stboot_mbr_installation.img2 : start=       28672, size=     1570817, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, uuid=4DCFBA35-047C-4B07-ACEB-EE208D76B779, name="STDATA"
#
# 1st partition:
# 2048 blocks * 512 bytes per block -> 1048576 
mount -o loop,offset=1048576 "${img}" "${mnt}_boot" || { echo -e "mount 1st partition $failed"; exit 1; }
echo "[INFO]: mounted 1st partition of $(realpath --relative-to=${root} ${img}) at ${mnt}_boot"

trap - EXIT