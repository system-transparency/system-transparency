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

mnt=$(mktemp -d -t "mnt-st-XXXX")
img="${dir}/Syslinux_Linuxboot.img"
initrd="${root}/stboot/initramfs-linuxboot.cpio.gz"

[ -f "${initrd}" ] || { echo "${initrd} does not exist"; echo "Including initramfs into image $failed";  exit 1; }

mkdir -p "${mnt}" || { echo -e "mkdir $failed"; exit 1; }
sleep 1		  # helps mount from failing with 32 ("mount failure")
mount -o loop,offset=1048576 "${img}" "${mnt}" || { echo -e "mount $failed"; exit 1; }
cp  "${initrd}" "${mnt}" || { echo -e "cp $failed"; exit 1; }
umount "${mnt}" || { echo -e "umount $failed"; exit 1; }
rm -r -f "${mnt}" || { echo -e "cleanup tmpdir $failed"; exit 1; }
echo "[INFO]: successfully moved $(realpath --relative-to=${root} ${initrd}) to $(realpath --relative-to=${root} ${img})"
