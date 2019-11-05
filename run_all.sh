#! /bin/bash

echo "############################################################"
echo " 1. step:"
echo " (Re)build the stconfig tool"
echo "############################################################"
echo "                                                     "
cd stconfig
bash ./install_stconfig.sh
cd ..

echo "############################################################"
echo " next step:"
echo " Utilize stconfi tool and upload resulting zip file"
echo "############################################################"
echo "                                                     "
while true; do
    read -p "Continue? (y/n)" yn
    case $yn in
        [Yy]* ) cd stconfig; bash ./make_and_upload_bootconfig.sh; cd ..; break;;
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
        [Yy]* ) cd stboot; bash ./install-u-root.sh; bash ./make_initramfs.sh; cd ..; break;;
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
        [Yy]* ) cd deploy/image; sudo bash ./mv_initrd_to_image.sh; sudo bash ./mv_netvars_to_image.sh; cd ../..; break;;
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
