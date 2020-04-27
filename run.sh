#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

failed="\e[1;5;31mfailed\e[0m"

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="${dir}"

# Source global build config file.
run_config=${root}/run.config
[ -r ${run_config} ] && source ${run_config}

# Set up operating-system configuration.
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
      echo "Option -${OPTARG} requires a path as an argument." >&2
      exit 1
      ;;
  esac
done

# initially create empty provisioning server access file
file="${root}/stconfig/prov-server-access.sh"
if [ ! -f ${file} ]; then
   echo "[INFO]: Create empty $(realpath --relative-to=${root} ${file}) configuration file"
   echo '
#!/bin/bash

# The script upoad_bootball.sh uses this data during uplaod.
# Upload is done via scp, so make sure ssh key are setup right on the server.

# prov_server is the URL of the provisioning server.
prov_server=""

# prov_server_user is the username at the provisioning server.
prov_server_user=""

# prov_server_path is the web root of the provisioning server.
prov_server_path=""
   ' > ${file}
fi


source "${dir}/checks.sh" || { echo -e "$failed : ${cfg} not found"; exit 1; }

echo ""
echo "Checking dependencies ..."
checkGCC
checkGO
checkMISC

echo ""
echo "Checking environment ..."
checkDebootstrap
checkProvServerSettings


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
      [Rr]* ) bash "${root}/stboot/data/create_example_data.sh" "${run_config}"; break;;
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
   echo "Run  (1) update sources and build u-root command"
   echo "Run  (2) rebuild u-root command"
   echo "Run  (3) choose custom branch and rebuild u-root command"
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
   echo "Run  (c) including u-root core tools"
   echo "Skip (s)"
   echo "Quit (q)"
   read -rp ">> " x
   case $x in
      [Rr]* ) bash "${root}/stboot/make_initramfs.sh"; break;;
      [Cc]* ) bash "${root}/stboot/make_initramfs.sh" -c; break;;
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
   echo "configuration: $(realpath --relative-to=${root} ${config})"
   cat ${config}
   echo ""
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
bootball_pattern="stboot.ball*"
dir=$(dirname "${config}")
files=( ${dir}/$bootball_pattern )
[ "${#files[@]}" -gt "1" ] && { echo -e "upload $failed : more then one bootbool files in $(dirname "${dir}")"; exit 1; }
bootball=${files[0]}
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
      [Rr]* ) bash "${root}/start_qemu_mixed-firmware.sh" "${run_config}"; break;;
      [Ss]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid input";;
   esac
done
