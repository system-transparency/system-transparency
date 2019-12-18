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

mnt=$(mktemp -d -t "mnt-st-XXXX")
img="${dir}/MBR_Syslinux_Linuxboot.img"
initrd="${root}/stboot/initramfs-linuxboot.cpio"

[ -f ${initrd} ] || { echo "${initrd} does not exist"; echo "Including initramfs into image $failed";  exit 1; }

echo "[INFO]: look for loop device"
losetup -f || { echo -e "losetup $failed"; exit 1; }
dev=$(losetup -f)

echo "[INFO]: setup ${img} to ${dev} and mout at ${mnt}"
losetup ${dev} ${img} || { echo -e "losetup $failed"; exit 1; }
partx -u ${dev} || { echo -e "partx $failed"; losetup -d ${dev}; exit 1; }
mkdir -p ${mnt} || { echo -e "mkdir $failed"; losetup -d ${dev}; exit 1; }
mount ${dev}p1 ${mnt} || { echo -e "mount $failed"; losetup -d ${dev}; exit 1; }
cp -v ${initrd} ${mnt} || { echo -e "cp $failed"; losetup -d ${dev}; exit 1; }
umount ${mnt} || { echo -e "umount $failed"; losetup -d ${dev}; exit 1; }
rm -r -f ${mnt} || { echo -e "cleanup tmpdir $failed"; losetup -d ${dev}; exit 1; }
losetup -d ${dev} || { echo -e "losetup -d $failed"; exit 1; }
echo "[INFO]: loop device is free again"
