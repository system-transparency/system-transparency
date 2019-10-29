#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

if [ -z "$var" ]
then
      echo "usage: umount.sh path/tp/loopdev"
fi

DEV=$1
MNTPOINT="/tmp/img"
IMG="BIOS_MBR_FAT_Syslinux_Linuxboot_OS.img"

echo "[INFO]: unmount $IMG"
umount $MNTPOINT || { echo 'umount failed'; exit 1; }
partx -d $DEV || { echo 'partx -d failed'; exit 1; }
losetup -d $DEV || { echo 'losetup -d failed'; exit 1; }
echo "[INFO]: loop device is free again"
