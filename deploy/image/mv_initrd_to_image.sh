#!/bin/bash
BASE=$(dirname "$0")

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

MNTPOINT="/tmp/img"
IMG="$BASE/BIOS_MBR_FAT_Syslinux_Linuxboot_OS.img"
INITRD="$BASE/../../stboot/initramfs_uroot.cpio"

echo "[INFO]: looking for loop device ..."
losetup -f || { echo 'losetup failed'; exit 1; }
DEV=$(losetup -f)
echo "[INFO]: using $DEV"

echo "[INFO]: setup img to dev/$DEV and mout at $MNTPOINT"
losetup $DEV $IMG || { echo 'losetup failed'; exit 1; }
partx -a $DEV || { echo 'partx failed'; exit 1; }
mkdir -p $MNTPOINT || { echo 'mkdir failed'; exit 1; }
mount ${DEV}p1 $MNTPOINT || { echo 'mount failed'; exit 1; }
cp $INITRD $MNTPOINT || { echo 'cp failed'; exit 1; }
echo "[INFO]: moved $INITRD to $IMG"
umount $MNTPOINT || { echo 'umount failed'; exit 1; }
partx -d $DEV || { echo 'partx -d failed'; exit 1; }
losetup -d $DEV || { echo 'losetup -d failed'; exit 1; }
echo "[INFO]: loop device is free again"
