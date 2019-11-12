#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

failed="\e[1;5;31mfailed\e[0m"
BASE=$(dirname "$0")
MNT="/tmp/mnt_stimg"
IMG="$BASE/MBR_Syslinux_Linuxboot.img"

echo "[INFO]: looking for loop device ..."
losetup -f || { echo -e "losetup $failed"; exit 1; }
DEV=$(losetup -f)

echo "[INFO]: setup img to $DEV"
losetup $DEV $IMG || { echo -e "losetup $failed"; exit 1; }
partx -u $DEV || { echo -e "partx $failed"; losetup -d $DEV; exit 1; }
mkdir -p $MNT || { echo -e "mkdir $failed"; losetup -d $DEV; exit 1; }
mount ${DEV}p1 $MNT || { echo -e "mount $failed"; losetup -d $DEV; exit 1; }
echo "[INFO]: mouned $IMG at $MNT"
