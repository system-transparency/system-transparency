#!/bin/bash

BASE=$(dirname "$0")

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

mnt=$(mktemp -d -t "mnt-st-XXXX")
img="${dir}/MBR_Syslinux_Linuxboot.img"
var_file_name="hostvars.json"
var_file="${root}/stboot/${var_file_name}"

[ -f ${var_file} ] || { echo "${var_file} does not exist"; echo "Including ${var_file_name} into image $failed";  exit 1; }

echo "[INFO]: looking for loop device"
losetup -f || { echo 'losetup $failed'; exit 1; }
dev=$(losetup -f)

echo "[INFO]: setup $img to $dev and mout at $mnt"
losetup ${dev} ${img} || { echo -e "losetup $failed"; exit 1; }
partx -u ${dev} || { echo -e "partx $failed"; losetup -d ${dev}; exit 1; }
mkdir -p ${mnt} || { echo -e "mkdir $failed"; losetup -d ${dev}; exit 1; }
mount ${dev}p1 ${mnt} || { echo -e "mount $failed"; losetup -d ${dev}; exit 1; }
cp -v ${var_file} ${mnt}
umount ${mnt} || { echo -e "umount $failed"; losetup -d ${dev}; exit 1; }
rm -r -f ${mnt} || { echo -e "cleanup tmpdir $failed"; losetup -d ${dev}; exit 1; }
losetup -d ${dev} || { echo -e "losetup -d $failed"; losetup -d ${dev}; exit 1; }
echo "[INFO]: loop device is free again"

