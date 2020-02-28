#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi

if [ "$#" -ne 1 ]
then
   echo "$0 USER"
   exit 1
fi

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

failed="\e[1;5;31mfailed\e[0m"

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

img="${dir}/MBR_Syslinux_Linuxboot.img"
img_backup="${dir}/MBR_Syslinux_Linuxboot.img.backup"
part_table="${dir}/mbr.table"
syslinux_src="https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/"
syslinux_tar="syslinux-6.03.tar.xz"
syslinux_dir="syslinux-6.03"
syslinux_config="${dir}/syslinux.cfg"
lnxbt_kernel="${dir}/vmlinuz-linuxboot"
tmp=$(mktemp -d -t stimg-XXXXXXXX)
mnt=$(mktemp -d -t stmnt-XXXXXXXX)

user_name="$1"

if ! id "${user_name}" >/dev/null 2>&1
then
   echo "User ${user_name} does not exist"
   exit 1
fi

if [ -f "${img}" ]; then
    while true; do
       echo "Current image file:"
       ls -l "$img"
       read -rp "Update? (y/n)" yn
       case $yn in
          [Yy]* ) echo "[INFO]: backup existing image to ${img_backup}"; mv "${img}" "${img_backup}"; break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
       esac
    done 
fi

echo "[INFO]: check for Linuxboot kernel"
bash "${dir}/build_kernel.sh"

if [ ! -f "${lnxbt_kernel}" ]; then
    echo "${lnxbt_kernel} not found!"
    echo -e "creating image $failed"; exit 1
else
    echo "Linuxboot kernel:  ${lnxbt_kernel}"
fi



echo "[INFO]: Downloading Syslinux Bootloader"
wget "${syslinux_src}/${syslinux_tar}" -P "${tmp}" || { echo -e "Download $failed"; exit 1; }
tar -xf "${tmp}/${syslinux_tar}" -C "${tmp}" || { echo -e "Decompression $failed"; exit 1; }

echo "[INFO]: Creating raw image"
dd if=/dev/zero "of=${img}" bs=1M count=200
losetup -f || { echo -e "Finding free loop device $failed"; exit 1; }
dev=$(losetup -f)
losetup "${dev}" "${img}" || { echo -e "Loop device setup $failed"; losetup -d "${dev}"; exit 1; }
sfdisk --no-reread --no-tell-kernel "${dev}" < "${part_table}" || { echo -e "partitioning $failed"; losetup -d "${dev}"; exit 1; }
partx -u "${dev}" || { echo -e "partx $failed"; losetup -d "${dev}"; exit 1; }
mkfs -t vfat "${dev}p1" || { echo -e "Creating filesystem $failed"; losetup -d "${dev}"; exit 1; }

echo "[INFO]: Installing Syslinux"
mount "${dev}p1" "${mnt}" || { echo -e "Mounting ${dev}p1 $failed"; losetup -d "${dev}"; exit 1; }
mkdir  "${mnt}/syslinux" || { echo -e "Making Syslinux config directory $failed"; losetup -d "${dev}"; exit 1; }
umount "${mnt}" || { echo -e "Unmounting $failed"; losetup -d "${dev}"; exit 1; }
"${tmp}/${syslinux_dir}/bios/linux/syslinux" --directory /syslinux/ --install "${dev}p1" || { echo -e "Writing vollume boot record $failed"; "${dev}"; exit 1; }
dd bs=440 count=1 conv=notrunc "if=${tmp}/${syslinux_dir}/bios/mbr/mbr.bin" "of=${dev}" || { echo -e "Writing master boot record $failed"; losetup -d "${dev}"; exit 1; }
mount "${dev}p1" "${mnt}" || { echo -e "Mounting ${dev}p1 $failed"; losetup -d "$dev"; exit 1; }
cp "${syslinux_config}" "${mnt}/syslinux"
cp "${lnxbt_kernel}" "${mnt}"


umount "${mnt}" || { echo -e "Unmounting $failed"; losetup -d "$dev"; exit 1; }
losetup -d "${dev}" || { echo -e "Loop device clean up $failed"; exit 1; }
rm -r -f "${tmp}" "${mnt}"

chown -c "${user_name}" "${img}"
chown -c "${user_name}" "${lnxbt_kernel}"

echo ""
echo "${img} created."
echo "Linuxboot initramfs needs to be included."

