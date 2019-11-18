#! /bin/bash

BASE=$(dirname "$0")

while getopts ":d" opt; do
  case $opt in
    d)
      echo
      echo "Run in developer mode!" >&2
      echo
      DEVELOP=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

MANIFEST=${1:-configs/example/manifest.json}

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
echo " (Re)build stconfig tool"
echo "############################################################"
echo "                                                     "
bash ./stconfig/install_stconfig.sh

echo "############################################################"
echo " Utilize stconfig tool and upload resulting boot file"
echo "############################################################"
echo "                                                     "
while true; do
    read -p "Continue? (y/n)" yn
    case $yn in
        [Yy]* ) bash ./stconfig/make_and_upload_bootconfig.sh $MANIFEST; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done


echo "                                                     "
echo "############################################################"
echo " (Re)build u-root command"
echo "############################################################"
echo "                                                     "
while true; do
    read -p "Continue? (y/n)" yn
    case $yn in
        [Yy]* ) bash ./stboot/install-u-root.sh; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo "                                                     "
echo "############################################################"
echo " Use u-root to create linuxboot initramfs"
echo "############################################################"
echo "                                                     "
while true; do
    read -p "Continue? (y/n)" yn
    case $yn in
        [Yy]* ) if [ $DEVELOP ]; then bash ./stboot/make_initramfs.sh dev; else bash ./stboot/make_initramfs.sh; fi; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo "                                                     "
echo "############################################################"
echo " Include initramfs into linuxboot image"
echo "############################################################"
echo "                                                     "
while true; do
    read -p "Continue as root? (y/n)" yn
    case $yn in
        [Yy]* ) sudo bash ./deploy/image/mv_initrd_to_image.sh; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done   

echo "                                                     "
echo "############################################################"
echo " Include netvars.json into linuxboot image"
echo "############################################################"
echo "                                                     "
while true; do
    read -p "Continue as root? (y/n)" yn
    case $yn in
        [Yy]* ) sudo bash ./deploy/image/mv_netvars_to_image.sh; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done   


echo "                                                     "
echo "############################################################"
echo " Run QEMU with linuxboot image"
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
