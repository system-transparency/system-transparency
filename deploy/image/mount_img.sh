#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

MNTPOINT="/tmp/img"
IMG="MBR_Syslinux_Linuxboot.img"

echo "[INFO]: looking for loop device ..."
losetup -f || { echo 'losetup failed'; exit 1; }
DEV=$(losetup -f)
echo "[INFO]: using $DEV"

echo "[INFO]: setup img to dev/$DEV and mout at $MNTPOINT"
losetup $DEV $IMG || { echo 'losetup failed'; exit 1; }
partx -a $DEV || { echo 'partx failed'; exit 1; }
mkdir -p $MNTPOINT || { echo 'mkdir failed'; exit 1; }
mount ${DEV}p1 $MNTPOINT || { echo 'mount failed'; exit 1; }
echo "[INFO]: mouned $IMG at $MNTPOINT"
