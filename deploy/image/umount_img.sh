#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

if [ -z "$var" ]
then
      echo "usage: umount.sh path/to/loopdev"
fi

failed="\e[1;5;31mfailed\e[0m"
BASE=$(dirname "$0")

DEV=$1
MNT="/tmp/mnt_stimg"
IMG="$BASE/MBR_Syslinux_Linuxboot.img"

echo "[INFO]: unmount $IMG"
umount $MNT || { echo -e "umount $failed"; losetup -d $DEV; exit 1; }
rm -r -f $MNT || { echo -e "cleanup tmpdir $failed"; losetup -d $DEV; exit 1; } 
losetup -d $DEV || { echo -e "losetup -d $failed"; exit 1; }
echo "[INFO]: loop device is free again"
