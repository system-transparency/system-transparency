#! /bin/bash

BASE=$(dirname "$0")

IMG="deploy/image/MBR_Syslinux_Linuxboot.img"
if [ ! -f "$IMG" ]; then
    while true; do
       echo "$IMG does not exist."
       read -p "Create now? Root privileges are required. (y/n)" yn
       case $yn in
          [Yy]* ) sudo bash ./deploy/image/create_image.sh; break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
       esac
    done
fi

echo "############################################################"
echo " 1. step:"
echo " (Re)build the stconfig tool"
echo "############################################################"
echo "                                                     "
bash ./stconfig/install_stconfig.sh

echo "############################################################"
echo " next step:"
echo " Utilize stconfi tool and upload resulting zip file"
echo "############################################################"
echo "                                                     "
while true; do
    read -p "Continue? (y/n)" yn
    case $yn in
        [Yy]* ) bash ./stconfig/make_and_upload_bootconfig.sh; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done  


echo "                                                     "
echo "############################################################"
echo " next step:"
echo " Update repo, rebuild u-root cmd and create initrd"
echo "############################################################"
echo "                                                     "
while true; do
    read -p "Continue? (y/n)" yn
    case $yn in
        [Yy]* ) bash ./stboot/install-u-root.sh; bash ./stboot/make_initramfs.sh; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done   


echo "                                                     "
echo "############################################################"
echo " next step:"
echo " Include updated initrd and netvars.json into syslinux image"
echo "############################################################"
echo "                                                     "
while true; do
    read -p "Continue as root? (y/n)" yn
    case $yn in
        [Yy]* ) sudo bash ./deploy/image/mv_initrd_to_image.sh; sudo bash ./deploy/image/mv_netvars_to_image.sh; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done   

echo "                                                     "
echo "############################################################"
echo " next step:"
echo " Run QEMU"
echo "############################################################"
echo "                                                     "
while true; do
    read -p "Continue? (y/n)" yn
    case $yn in
        [Yy]* ) bash ./start_qemu_image.sh; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
