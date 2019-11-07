#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

BASE=$(dirname "$0")

IMG="$BASE/MBR_Syslinux_Linuxboot.img"
PARTTABLE="$BASE/mbr.table"
SYSLINUX_SRC="https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/"
SYSLINUX_TAR="syslinux-6.03.tar.xz"
SYSLINUX_DIR="syslinux-6.03"
SYSLINUX_CFG="$BASE/syslinux.cfg"
LNXBT_KERNEL="$BASE/vmlinuz-linuxboot"
TMP=$(mktemp -d -t stimg-XXXXXXXX)
MNT=$(mktemp -d -t stmnt-XXXXXXXX)

if [ -f "$IMG" ]; then
    while true; do
       read -p "$IMG already exists! Override? (y/n)" yn
       case $yn in
          [Yy]* ) rm $IMG; break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
       esac
    done 
fi

echo "____ Downloading Syslinux Bootloader ____"
wget $SYSLINUX_SRC/$SYSLINUX_TAR -P $TMP || { echo 'Download failed'; exit 1; }
tar -xf $TMP/$SYSLINUX_TAR -C $TMP || { echo 'Decompression failed'; exit 1; }

echo "____ Creating raw image ____"
dd if=/dev/zero of=$IMG bs=1M count=200
losetup -f || { echo 'No free loop device found'; exit 1; }
DEV=$(losetup -f)
losetup $DEV $IMG || { echo 'Loop device setup failed'; losetup -d $DEV; exit 1; }
sfdisk --no-reread --no-tell-kernel $DEV < $PARTTABLE || { echo 'Partitioning failed'; losetup -d $DEV; exit 1; }
partx -u $DEV || { echo 'partx failed'; losetup -d $DEV; exit 1; }
mkfs -t vfat ${DEV}p1 || { echo 'Creating filesystem failed'; losetup -d $DEV; exit 1; }

echo "____ Installing Syslinux ____"
mount ${DEV}p1 $MNT || { echo 'Mounting ${DEV}p1 failed'; losetup -d $DEV; exit 1; }
mkdir  $MNT/syslinux || { echo 'Making Syslinux config directory failed'; losetup -d $DEV; exit 1; }
umount $MNT || { echo 'Unmounting failed'; losetup -d $DEV; exit 1; }
$TMP/$SYSLINUX_DIR/bios/linux/syslinux --directory /syslinux/ --install ${DEV}p1 || { echo 'Writing vollume boot record failed'; $DEV; exit 1; }
dd bs=440 count=1 conv=notrunc if=$TMP/$SYSLINUX_DIR/bios/mbr/mbr.bin of=$DEV || { echo 'Writing master boot record failed'; losetup -d $DEV; exit 1; }
mount ${DEV}p1 $MNT || { echo 'Mounting ${DEV}p1 failed'; losetup -d $DEV; exit 1; }
cp $SYSLINUX_CFG $MNT/syslinux
cp $LNXBT_KERNEL $MNT


umount $MNT || { echo 'Unmounting failed'; losetup -d $DEV; exit 1; }
losetup -d $DEV || { echo 'Loop device clean up failed'; exit 1; }
rm -r -f $TMP $MNT

read -p "Type your username to own the image file:" user
chown -c $user:$user $IMG

echo ""
echo "$IMG created. Initramfs needs to be included."

