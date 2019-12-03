#!/bin/sh

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

failed="\e[1;5;31mfailed\e[0m"

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
file="${dir}/$(basename "${BASH_SOURCE[0]}")"
base="$(basename ${file} .sh)"
root="$(cd "${dir}/../../" && pwd)"

kernel="debian-buster-amd64.vmlinuz"
initrd="debian-buster-amd64.cpio.gz"

#Check if debian config directory already exists
if [ -d ${root}/configs/debian-buster-amd64/manifest.json ]; then
    while true; do
       read -p "${root}/configs/debian-buster-amd64/manifest.json already exists! Update? (y/n)" yn
       case $yn in
          [Yy]* ) rmdir -v --ignore-fail-on-non-empty ${root}/configs/debian; break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
       esac
    done 
fi

if [ ! -f "${dir}/docker/out/${kernel}" ] || [ ! -f "${dir}/docker/out/${initrd}" ]; then
    while true; do
       read -p "$debian kernel or filesystem missing. Build reproducible debian now? (y/n)" yn
       case $yn in
          [Yy]* ) bash ${dir}/run-docker.sh; break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
       esac
    done 
fi


echo "____Copy nessesary files to config directory____"
mkdir -p ${root}/configs/debian-buster-amd64/kernels && cp -v ${dir}/docker/out/${kernel} ${root}/configs/debian-buster-amd64/kernels
mkdir -p ${root}/configs/debian-buster-amd64/initrds && cp -v ${dir}/docker/out/${initrd} ${root}/configs/debian-buster-amd64/initrds
mkdir -p ${root}/configs/debian-buster-amd64/signing && cp -v ${root}/testitems/signing/root.cert ${root}/configs/debian-buster-amd64/signing

echo "____Create manifest.json for debian boot configuration____"
touch ${root}/configs/debian-buster-amd64/manifest.json
sudo echo '{ 
  "version": 1, 
  "configs": [ 
    { 
      "name": "debian buster reproducible", 
      "kernel": "kernels/'$kernel'", 
      "kernel_args": "console=tty0 console=ttyS0,115200n8 rw rdinit=/lib/systemd/systemd", 
      "initramfs": "initrds/'$initrd'" 
    } 
  ], 
  "rootCert": "signing/root.cert" 
}' > ${root}/configs/debian-buster-amd64/manifest.json

cat ${root}/configs/debian-buster-amd64/manifest.json

echo "Successfully createt ${root}/configs/debian-buster-amd64/manifest.json"
