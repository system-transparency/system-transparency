#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="${dir}"

function checkGCC {
   maxver="8"

   command -v gcc >/dev/null 2>&1 || { 
      echo >&2 "GCC required";
      exit 1;
   }

   currentver="$(gcc -dumpversion | cut -d . -f 1)"

   if [ "$currentver" -gt "$maxver" ]; then 
         echo "GCC version ${currentver} is not supported. Need version ${maxver} or earlier."
         exit 1
   else
       echo "GCC supported"
   fi
}

function checkGO {
   minver=("1" "11") 

   command -v go >/dev/null 2>&1 || { 
      echo >&2 "GO required";
      exit 1;
   }

   majorver="$(go version | sed 's/go version go//' | cut -d . -f 1)"
   minorver="$(go version | sed 's/go version go//' | cut -d . -f 2)"

   if [ "$majorver" -le "${minver[0]}" ] && [ "$minorver" -lt "${minver[1]}" ]; then 
         echo "GO version ${majorver}.${minorver} is not supported. Need version ${minver[0]}.${minver[1]} or later."
         exit 1
   else
       echo "GO supported"
   fi

   echo "$PATH"|grep -q "$(go env GOPATH)/bin" || { echo "$(go env GOPATH)/bin must be added to PATH"; exit 1; }
}



checkGCC
checkGO

config=${root}/configs/debian-buster-amd64/stconfig.json
while getopts ":c:" opt; do
  case $opt in
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

echo "Checking dependencies ..."
cmds=( "git" "openssl" "docker" "gpg" "gpgv" "qemu-system-x86_64" "id" \
        "wget" "dd" "losetup" "sfdisk" "partx" "partprobe" "mkfs" "mount" "umount" "shasum" "ssh" "scp" "sudo" \
        "bison" "flex" "pkg-config" "bc" "date" "jq" "make" "mkfs.vfat")
libs=( "libelf" "libcrypto" )

for i in "${cmds[@]}"
do
    PATH=/usr/sbin:$PATH command -v "$i" >/dev/null 2>&1 || {
        echo >&2 "$i required"; 
        exit 1; 
    }
done

for i in "${libs[@]}"
do
   pkg-config "$i" >/dev/null 2>&1 || {
      echo >&2 "$i required";
      exit 1;
   }
done

if [[ ! -f "/lib/ld-linux.so.2" ]]
then
   echo "i386 libc required";
   exit 1
fi

if findmnt -T "${root}" | grep -cq "nodev"
then
   echo "The directory ${root} is mounted with nodev option but debootstrap needs to mknod to work."
   exit 1
fi

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
   read -rp ">> " x
   case $x in
      [Rr]* ) bash "${root}/keys/generate-keys-and-certs.sh"; break;;
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
   read -rp ">> " x
   case $x in
      [Rr]* ) bash "${root}/stboot/create_hostvars.sh"; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

echo
echo "############################################################"
echo " Create example data files"
echo "############################################################"
echo "                                                      "
while true; do
   echo "Run  (r)"
   echo "Skip (s)"
   echo "Quit (q)"
   read -rp ">> " x
   case $x in
      [Rr]* ) bash "${root}/stboot/data/create_example_data.sh"; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

echo
echo "############################################################"
echo " Build bootloader image for mixed-firmware deployment"
echo "############################################################"
echo "                                                      "
while true; do
   echo "Run  (r) Root privileges are required"
   echo "Skip (s)"
   echo "Quit (q)"
   read -rp ">> " x
   case $x in
      [Rr]* ) sudo bash "${root}/deploy/mixed-firmware/create_image.sh" "$(id -un)"; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

echo
echo "############################################################"
echo " Setup boot configuration for reproducible Debian OS"
echo "############################################################"
echo "                                                      "
while true; do
   echo "Run  (r) Root privileges may be required"
   echo "Skip (s)"
   echo "Quit (q)"
   read -rp ">> " x
   case $x in
      [Rr]* ) bash "${root}/operating-system/debian/create-stconfig.sh"; break;;
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
   echo "Run  (1) update sources and build u-root cmd"
   echo "Run  (2) rebuild u-root cmd"
   echo "Run  (3) choose custom branch and rebuild u-root cmd" 
   echo "Skip (s)"
   echo "Quit (q)"
   read -rp ">> " x
   case $x in
      [1]* ) bash "${root}/stboot/install_u-root.sh" -u; break;;
      [2]* ) bash "${root}/stboot/install_u-root.sh"; break;;
      [3]* ) bash "${root}/stboot/install_u-root.sh" -b; break;;
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
   echo "Run  (1) update sources and build stconfig tool"
   echo "Run  (2) rebuild stconfig tool"
   echo "Run  (3) choose custom branch and rebuild stconfig tool" 
   echo "Skip (s)"
   echo "Quit (q)"
   read -rp ">> " x
   case $x in
      [1]* ) bash "${root}/stconfig/install_stconfig.sh" -u; break;;
      [2]* ) bash "${root}/stconfig/install_stconfig.sh"; break;;
      [3]* ) bash "${root}/stconfig/install_stconfig.sh" -b; break;;
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
   read -rp ">> " x
   case $x in
      [Rr]* ) bash "${root}/stboot/make_initramfs.sh"; break;;
      [Dd]* ) bash "${root}/stboot/make_initramfs.sh" -d; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

echo "                                                     "
echo "############################################################"
echo " Include initramfs into bootloader image"
echo "############################################################"
echo "                                                     "
while true; do
   echo "Run  (r) Root privileges are required"
   echo "Skip (s)"
   echo "Quit (q)"
   read -rp ">> " x
   case $x in
      [Rr]* ) sudo bash "${root}/deploy/mixed-firmware/mv_initrd_to_image.sh"; break;;
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
   read -rp ">> " x
   case $x in
      [Rr]* ) bash "${root}/stconfig/create_and_sign_bootball.sh" "${config}"; break;;
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
   read -rp ">> " x
   case $x in
      [Rr]* ) bash "${root}/stconfig/upload_bootball.sh" "${bootball}"; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done


echo "                                                     "
echo "############################################################"
echo " Run QEMU with mixed-firmware image"
echo "############################################################"
echo "                                                     "
while true; do
   echo "Run  (r)"
   echo "Skip (s)"
   echo "Quit (q)"
   read -rp ">> " x
   case $x in
      [Rr]* ) bash "${root}/start_qemu_mixed-firmware.sh"; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

