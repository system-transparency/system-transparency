#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

BASE=$(dirname "$0")
MNT="/tmp/mnt_stimg"
IMG="$BASE/MBR_Syslinux_Linuxboot.img"

echo "[INFO]: looking for loop device ..."
losetup -f || { echo 'losetup failed'; exit 1; }
DEV=$(losetup -f)

echo "[INFO]: setup img to $DEV"
losetup $DEV $IMG || { echo 'losetup failed'; exit 1; }
partx -u $DEV || { echo 'partx failed'; losetup -d $DEV; exit 1; }
mkdir -p $MNT || { echo 'mkdir failed'; losetup -d $DEV; exit 1; }
mount ${DEV}p1 $MNT || { echo 'mount failed'; losetup -d $DEV; exit 1; }
echo "[INFO]: mouned $IMG at $MNT"
