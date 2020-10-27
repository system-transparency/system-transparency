#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

failed="\e[1;5;31mfailed\e[0m"

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="${dir}"

# Source script with environment checks.
checks=${root}/scripts/checks.sh
[ -r "${checks}" ] && source "${checks}"

echo ""
echo "Checking dependencies ..."
checkGCC
checkGO
checkMISC

echo ""
echo "Checking environment ..."
checkDebootstrap
checkSwtpmSetup
checkSwtpm
checkOVMF

# Global build configuration
global_config=${root}/run.config

bash "${root}/scripts/make_global_config.sh"

source ${global_config}


echo
echo "############################################################"
echo " Install toolchain"
echo "############################################################"
echo
while true; do
   echo "Run  (r)"
   echo "Skip (s)"
   echo "Quit (q)"
   read -rp ">> " x
   case $x in
      [Rr]* ) bash "${root}/scripts/make_toolchain.sh"; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

echo
echo "############################################################"
echo " Generate example keys and certificates"
echo "############################################################"
echo
while true; do
   echo "Run  (r)"
   echo "Skip (s)"
   echo "Quit (q)"
   read -rp ">> " x
   case $x in
      [Rr]* ) bash "${root}/scripts/make_keys_and_certs.sh"; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

echo
echo "############################################################"
echo " Build Operating Sytem"
echo "############################################################"
echo
while true; do
   echo "Run  (r) Reproducible Debian Buster"
   echo "Skip (s)"
   echo "Quit (q)"
   read -rp ">> " x
   case $x in
      [Rr]* ) bash "${root}/operating-system/debian/make_debian.sh"; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

echo
echo "############################################################"
echo " Use stmanager to create a OS package with Debian Buster and"
echo " sign with example keys"
echo "############################################################"
echo
while true; do
   echo "[INFO]: You can use stmanager manually, too." 
   echo "[INFO]: Therefor quit and try 'stmanager --help-long'"
   echo ""
   echo "Run  (r)"
   echo "Skip (s)"
   echo "Quit (q)"
   read -rp ">> " x
   case $x in
      [Rr]* ) bash "${root}/scripts/create_and_sign_os_package.sh"; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

echo
echo "############################################################"
echo " Upload OS package to provisioning server"
echo "############################################################"
echo
os_package="${root}/.newest-ospkg.zip"
while true; do
   echo "OS package: $(realpath --relative-to="${root}" "${os_package}")"
   echo "Run  (r) with OS package"
   echo "Skip (s)"
   echo "Quit (q)"
   read -rp ">> " x
   case $x in
      [Rr]* ) bash "${root}/scripts/upload_os_package.sh" "${os_package}"; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

echo
echo "############################################################"
echo " Build bootloader "
echo "############################################################"
echo
while true; do
   echo "Run  (1) coreboot payload installation"
   echo "Run  (2) EFI executable installation"
   echo "Run  (3) MBR bootloader installation"
   echo "Skip (s)"
   echo "Quit (q)"
   read -rp ">> " x
   case $x in
      [1]* ) bash "${root}/stboot-installation/coreboot-payload/make_dummy.sh"; break;;
      [2]* ) bash "${root}/stboot-installation/efi-executable/make_efi_executable.sh"; break;;
      [3]* ) bash "${root}/stboot-installation/mbr-bootloader/make_mbr_bootloader.sh"; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

echo
echo "############################################################"
echo " Run in QEMU "
echo "############################################################"
echo
while true; do
   echo "Run  (1) coreboot payload installation"
   echo "Run  (2) EFI executable installation"
   echo "Run  (3) MBR bootloader installation"
   echo "Skip (s)"
   echo "Quit (q)"
   read -rp ">> " x
   case $x in
      [1]* ) bash "${root}/scripts/start_qemu_coreboot_payload.sh"; break;;
      [2]* ) bash "${root}/scripts/start_qemu_efi_executable.sh"; break;;
      [3]* ) bash "${root}/scripts/start_qemu_mbr_bootloader.sh"; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done

