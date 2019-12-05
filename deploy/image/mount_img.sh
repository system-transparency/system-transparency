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
file="${dir}/$(basename "${BASH_SOURCE[0]}")"
base="$(basename ${file} .sh)"
root="$(cd "${dir}/../../" && pwd)"

mnt="/tmp/mnt_stimg"
img="${dir}/MBR_Syslinux_Linuxboot.img"

echo "[INFO]: look for loop device"
losetup -f || { echo -e "losetup $failed"; exit 1; }
dev=$(losetup -f)

echo "[INFO]: setup image to ${dev}"
losetup ${dev} ${img} || { echo -e "losetup $failed"; exit 1; }
partx -u ${dev} || { echo -e "partx $failed"; losetup -d ${dev}; exit 1; }
mkdir -p ${mnt} || { echo -e "mkdir $failed"; losetup -d ${dev}; exit 1; }
mount ${dev}p1 ${mnt} || { echo -e "mount $failed"; losetup -d ${dev}; exit 1; }
echo "[INFO]: mounted ${img} at ${mnt}"
