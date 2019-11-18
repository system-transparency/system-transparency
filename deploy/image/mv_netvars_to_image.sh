#!/bin/bash

BASE=$(dirname "$0")

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

MNT=$(mktemp -d -t "mnt-st-XXXX")
IMG="$BASE/MBR_Syslinux_Linuxboot.img"
FILE="$BASE/../../stboot/include/netvars.json"

echo "[INFO]: looking for loop device ..."
losetup -f || { echo 'losetup failed'; exit 1; }
DEV=$(losetup -f)

echo "[INFO]: setup $IMG to $DEV and mout at $MNT"
losetup $DEV $IMG || { echo -e "losetup $failed"; exit 1; }
partx -u $DEV || { echo -e "partx $failed"; losetup -d $DEV; exit 1; }
mkdir -p $MNT || { echo -e "mkdir $failed"; losetup -d $DEV; exit 1; }
mount ${DEV}p1 $MNT || { echo -e "mount $failed"; losetup -d $DEV; exit 1; }
cp -v $FILE $MNT || { echo 'cp failed'; losetup -d $DEV; exit 1; }
umount $MNT || { echo -e "umount $failed"; losetup -d $DEV; exit 1; }
rm -r -f $MNT || { echo -e "cleanup tmpdir $failed"; losetup -d $DEV; exit 1; }
losetup -d $DEV || { echo -e "losetup -d $failed"; losetup -d $DEV; exit 1; }
echo "[INFO]: loop device is free again"

