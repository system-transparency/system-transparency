#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

failed="\e[1;5;31mfailed\e[0m"

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
file="${dir}/$(basename "${BASH_SOURCE[0]}")"
base="$(basename ${file} .sh)"
root="${dir}"

manifest=${root}/configs/debian-buster-amd64/manifest.json
while getopts ":dm:" opt; do
  case $opt in
    d)
      echo
      echo "Run in developer mode!" >&2
      echo
      develop=true
      ;;
    m)
      manifest=$OPTARG
      ;;
    \?)
      echo "Invalid option: -${OPTARG}" >&2
      exit 1
      ;;
    :)
      echo "Option -${OPTARG} requires a path argument." >&2
      exit 1
      ;;
  esac
done

echo "Checking dependancies ..."
array=( "go" "openssl" "docker" )
for i in "${array[@]}"
do
    command -v $i >/dev/null 2>&1 || { 
        echo >&2 "$i required"; 
        exit 1; 
    }
done

echo
echo "############################################################"
echo " Build bootloader image"
echo "############################################################"
echo "                                                      "
while true; do
   echo "Run  (r) Root privileges are required"
   echo "Skip (s)"
   echo "Quit (q)"
   read -p ">> " x
   case $x in
      [Rr]* ) sudo bash ${root}/deploy/image/create_image.sh; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

echo
echo "############################################################"
echo " Generate example keys and certificates"
echo "############################################################"
echo "                                                      "
while true; do
   echo "Run  (r)"
   echo "Skip (s)"
   echo "Quit (q)"
   read -p ">> " x
   case $x in
      [Rr]* ) bash ${root}/keys/generate-keys-and-certs.sh; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

echo
echo "############################################################"
echo " Build reproducible Debian OS"
echo "############################################################"
echo "                                                      "
while true; do
   echo "Run  (r) Root privileges may be required"
   echo "Skip (s)"
   echo "Quit (q)"
   read -p ">> " x
   case $x in
      [Rr]* ) bash ${root}/remote-os/debian/create-manifest.sh; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

echo
echo "############################################################"
echo " (Re)build stconfig tool"
echo "############################################################"
echo "                                                     "
while true; do
   echo "Run  (r)"
   echo "Skip (s)"
   echo "Quit (q)"
   read -p ">> " x
   case $x in
      [Rr]* ) bash ${root}/stconfig/install_stconfig.sh; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

echo
echo "############################################################"
echo " Utilize stconfig tool and upload resulting boot file"
echo "############################################################"
echo "                                                     "
while true; do
   echo "manifest: ${manifest}"
   echo "Run  (r) with manifest"
   echo "Skip (s)"
   echo "Quit (q)"
   read -p ">> " x
   case $x in
      [Rr]* ) bash ${root}/stconfig/make_and_upload_bootconfig.sh $manifest; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

echo "                                                     "
echo "############################################################"
echo " (Re)build u-root command"
echo "############################################################"
echo "                                                     "
while true; do
   echo "Run  (r)"
   echo "Skip (s)"
   echo "Quit (q)"
   read -p ">> " x
   case $x in
      [Rr]* ) bash ${root}/stboot/install-u-root.sh; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

echo "                                                     "
echo "############################################################"
echo " Use u-root to create linuxboot initramfs"
echo "############################################################"
echo "                                                     "
while true; do
   echo "Run  (r)"
   echo "Run  (d) with 'develop' flag"
   echo "Skip (s)"
   echo "Quit (q)"
   read -p ">> " x
   case $x in
      [Rr]* ) bash ${root}/stboot/make_initramfs.sh; break;;
      [Dd]* ) bash ${root}/stboot/make_initramfs.sh dev; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

echo "                                                     "
echo "############################################################"
echo " Include initramfs into linuxboot image"
echo "############################################################"
echo "                                                     "
while true; do
   echo "Run  (r) Root privileges are required"
   echo "Skip (s)"
   echo "Quit (q)"
   read -p ">> " x
   case $x in
      [Rr]* ) sudo bash ${root}/deploy/image/mv_initrd_to_image.sh; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

# netvars.json is included into the initramfs at the moment

#echo "                                                     "
#echo "############################################################"
#echo " Include netvars.json into linuxboot image"
#echo "############################################################"
#echo "                                                     "
#while true; do
#   echo "Run it. Root privileges are required (r)"
#   echo "Skip (s)"
#   echo "Quit (q)"
#   read -p ">> " x
#   case $x in
#      [Rr]* ) sudo bash ${root}/deploy/image/mv_netvars_to_image.sh; break;;
#      [Ss]* ) break;;
#      [Qq]* ) exit;;
#      * ) echo "Invalid input";;
#   esac
#done


echo "                                                     "
echo "############################################################"
echo " Run QEMU with linuxboot image"
echo "############################################################"
echo "                                                     "
while true; do
   echo "Run  (r)"
   echo "Skip (s)"
   echo "Quit (q)"
   read -p ">> " x
   case $x in
      [Rr]* ) bash ${root}/start_qemu_image.sh; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

