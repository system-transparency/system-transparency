#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi


failed="\e[1;5;31mfailed\e[0m"
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

if [ ! -f "$LNXBT_KERNEL" ]; then
    while true; do
       read -p "$LNXBT_KERNEL not found. Build kernel now? (y/n)" yn
       case $yn in
          [Yy]* ) bash ${BASE}/build_kernel.sh; break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
       esac
    done 
fi


echo "____ Downloading Syslinux Bootloader ____"
wget $SYSLINUX_SRC/$SYSLINUX_TAR -P $TMP || { echo -e "Download $failed"; exit 1; }
tar -xf $TMP/$SYSLINUX_TAR -C $TMP || { echo -e "Decompression $failed"; exit 1; }

echo "____ Creating raw image ____"
dd if=/dev/zero of=$IMG bs=1M count=200
losetup -f || { echo -e "Finding free loop device $failed"; exit 1; }
DEV=$(losetup -f)
losetup $DEV $IMG || { echo -e "Loop device setup $failed"; losetup -d $DEV; exit 1; }
sfdisk --no-reread --no-tell-kernel $DEV < $PARTTABLE || { echo -e "partitioning $failed"; losetup -d $DEV; exit 1; }
partx -u $DEV || { echo -e "partx $failed"; losetup -d $DEV; exit 1; }
mkfs -t vfat ${DEV}p1 || { echo -e "Creating filesystem $failed"; losetup -d $DEV; exit 1; }

echo "____ Installing Syslinux ____"
mount ${DEV}p1 $MNT || { echo -e "Mounting ${DEV}p1 $failed"; losetup -d $DEV; exit 1; }
mkdir  $MNT/syslinux || { echo -e "Making Syslinux config directory $failed"; losetup -d $DEV; exit 1; }
umount $MNT || { echo -e "Unmounting $failed"; losetup -d $DEV; exit 1; }
$TMP/$SYSLINUX_DIR/bios/linux/syslinux --directory /syslinux/ --install ${DEV}p1 || { echo -e "Writing vollume boot record $failed"; $DEV; exit 1; }
dd bs=440 count=1 conv=notrunc if=$TMP/$SYSLINUX_DIR/bios/mbr/mbr.bin of=$DEV || { echo -e "Writing master boot record $failed"; losetup -d $DEV; exit 1; }
mount ${DEV}p1 $MNT || { echo -e "Mounting ${DEV}p1 $failed"; losetup -d $DEV; exit 1; }
cp $SYSLINUX_CFG $MNT/syslinux
cp $LNXBT_KERNEL $MNT


umount $MNT || { echo -e "Unmounting $failed"; losetup -d $DEV; exit 1; }
losetup -d $DEV || { echo -e "Loop device clean up $failed"; exit 1; }
rm -r -f $TMP $MNT

read -p "Type your username to own the image file:" user
chown -c $user:$user $IMG
chown -c $user:$user $LNXBT_KERNEL

echo ""
echo "$IMG created. Initramfs needs to be included."

