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
currentver="$(gcc -dumpversion)"

function checkGCC {
   requiredver="8"
   if [ "$currentver" -gt "$requiredver" ]; then 
         echo "GCC not supported"
         exit 1
   else
       echo "GCC supported"
   fi
}

checkGCC

config=${root}/configs/debian-buster-amd64/stconfig.json
while getopts ":dc:" opt; do
  case $opt in
    d)
      echo
      echo "Run in developer mode!" >&2
      echo
      develop=true
      ;;
    c)
      config=$OPTARG
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
array=( "go" "git" "openssl" "docker" "gpg" "gpgv" "qemu-system-x86_64" \
        "wget" "dd" "losetup" "sfdisk" "partx" "mkfs" "mount" "umount" "shasum" "ssh" "scp")

for i in "${array[@]}"
do
    command -v $i >/dev/null 2>&1 || { 
        echo >&2 "$i required"; 
        exit 1; 
    }
done
echo "$PATH"|grep -q $(go env GOPATH)/bin || { echo "$(go env GOPATH)/bin must be added to PATH"; exit 1; }
echo "OK"

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
echo " Create example hostvars.json"
echo "############################################################"
echo "                                                      "
while true; do
   echo "Run  (r)"
   echo "Skip (s)"
   echo "Quit (q)"
   read -p ">> " x
   case $x in
      [Rr]* ) bash ${root}/stboot/create_hostvars.sh; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

# netvars.json is included into the initramfs at the moment

#echo "                                                     "
#echo "############################################################"
#echo " Include hostvars.json into linuxboot image"
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

echo
echo "############################################################"
echo " Build reproducible Debian OS and create config directory"
echo "############################################################"
echo "                                                      "
while true; do
   echo "Run  (r) Root privileges may be required"
   echo "Skip (s)"
   echo "Quit (q)"
   read -p ">> " x
   case $x in
      [Rr]* ) bash ${root}/remote-os/debian/create-stconfig.sh; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

echo "                                                     "
echo "############################################################"
echo " Build u-root command"
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

echo
echo "############################################################"
echo " Build stconfig tool"
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

echo
echo "############################################################"
echo " Use stconfig tool to create and sign bootball"
echo "############################################################"
echo "                                                     "
while true; do
   echo "configuration: ${config}"
   echo "Run  (r) with configuration"
   echo "Skip (s)"
   echo "Quit (q)"
   read -p ">> " x
   case $x in
      [Rr]* ) bash ${root}/stconfig/create_and_sign_bootball.sh ${config}; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

echo
echo "############################################################"
echo " Upload bootball to provisioning server"
echo "############################################################"
echo "                                                     "
bootball="$(dirname "${config}")/stboot.ball"
while true; do
   echo "bootball: ${bootball}"
   echo "Run  (r) with bootball"
   echo "Skip (s)"
   echo "Quit (q)"
   read -p ">> " x
   case $x in
      [Rr]* ) bash ${root}/stconfig/upload_bootball.sh ${bootball}; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done


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

