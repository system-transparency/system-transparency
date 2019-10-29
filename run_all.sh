#! /bin/bash

echo "############################################################"
echo " 1. step:"
echo " Rebuild the stconfig tool"
echo "############################################################"
echo "                                                     "
bash ./rebuild_stconfig.sh

echo "############################################################"
echo " next step:"
echo " Utilize stconfi tool and upload resulting zip file"
echo "############################################################"
echo "                                                     "
while true; do
    read -p "Continue? (y/n)" yn
    case $yn in
        [Yy]* ) bash ./make_and_upload_zip_file.sh; break;;
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
        [Yy]* ) bash ./update_rebuild_make_initramfs.sh; break;;
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
        [Yy]* ) sudo bash ./mv_initrd_to_image.sh; sudo bash ./mv_netvars_to_image.sh; break;;
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
        [Yy]* ) bash ./start_qemu.sh; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
