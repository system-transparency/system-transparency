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
root="$(cd "${dir}/../../" && pwd)"
mnt=$(mktemp -d -t stmnt-XXXXXXXX)

user_name="$1"

img="${dir}/efi_bootlayout.img"
part_table="${dir}/gpt.table"

echo "[INFO]: Creating raw image"
dd if=/dev/zero "of=${img}" bs=1M count=500
losetup -f || { echo -e "Finding free loop device $failed"; exit 1; }
dev=$(losetup -f)
losetup "${dev}" "${img}" || { echo -e "Loop device setup $failed"; losetup -d "${dev}"; exit 1; }
sfdisk --no-reread --no-tell-kernel "${dev}" < "${part_table}" || { echo -e "partitioning $failed"; losetup -d "${dev}"; exit 1; }
partprobe -s "${dev}" || { echo -e "partprobe $failed"; losetup -d "${dev}"; exit 1; }
echo "[INFO]: Make FAT filesystem for EFI partition"
mkfs.fat -F32 "${dev}p1" || { echo -e "Creating filesystem on 1st partition $failed"; losetup -d "${dev}"; exit 1; }
echo "[INFO]: Make EXT4 filesystem for data partition"
mkfs.ext4 "${dev}p2" || { echo -e "Creating filesystem on 2nd partition $failed"; losetup -d "${dev}"; exit 1; }
partprobe -s "${dev}" || { echo -e "partprobe $failed"; losetup -d "${dev}"; exit 1; }
echo "[INFO]: Raw image layout:"
lsblk -o NAME,SIZE,TYPE,PTTYPE,PARTUUID,PARTLABEL,FSTYPE ${dev}

echo ""
echo "[INFO]: Moving boot files"
mount "${dev}p1" "${mnt}" || { echo -e "Mounting ${dev}p1 $failed"; losetup -d "$dev"; exit 1; }
mkdir -p "${mnt}/EFI/BOOT" || { echo -e "Creating EFI boot directory $failed"; losetup -d "${dev}"; exit 1; }
cp "${dir}/stboot.efi" "${mnt}/EFI/BOOT/BOOTX64.EFI" || { echo -e "Copying files $failed"; losetup -d "$dev"; exit 1; }
umount "${mnt}" || { echo -e "Unmounting $failed"; losetup -d "$dev"; exit 1; }

echo "[INFO]: Moving data files"
mount "${dev}p2" "${mnt}" || { echo -e "Mounting ${dev}p2 $failed"; losetup -d "$dev"; exit 1; }
cp -R "${root}/stboot/data/." "${mnt}" || { echo -e "Copying files $failed"; losetup -d "$dev"; exit 1; }
umount "${mnt}" || { echo -e "Unmounting $failed"; losetup -d "$dev"; exit 1; }

losetup -d "${dev}" || { echo -e "Loop device clean up $failed"; exit 1; }
rm -rf "${mnt}"
echo ""
chown -c "${user_name}" "${img}"

echo ""
echo "[INFO]: $(realpath --relative-to=${root} ${img}) created."
