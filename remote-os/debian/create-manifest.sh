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
if [ -f ${root}/configs/debian-buster-amd64/manifest.json ]; then
    echo "clean config directory"
    rm -r ${root}/configs/debian-buster-amd64
fi

if [ ! -f "${dir}/docker/out/${kernel}" ] || [ ! -f "${dir}/docker/out/${initrd}" ]; then
    echo "[INFO]: Build reproducible Debian OS inside docker"
    echo "Root privileges are required"
    sudo bash ${dir}/run-docker.sh
else
    echo "[INFO]: Current Debian OS artefacts: "
    ls -l ${dir}/docker/out/${kernel}
    ls -l ${dir}/docker/out/${initrd}
    while true; do
       read -p "Update? Root privileges are required (y/n)" yn
       case $yn in
          [Yy]* ) sudo bash ${dir}/run-docker.sh; break;;
          [Nn]* ) break;;
          * ) echo "Please answer yes or no.";;
       esac
    done
fi

echo "[INFO]: Copy nessesary files to config directory"
mkdir -p ${root}/configs/debian-buster-amd64/kernels && cp -v ${dir}/docker/out/${kernel} ${root}/configs/debian-buster-amd64/kernels
mkdir -p ${root}/configs/debian-buster-amd64/initrds && cp -v ${dir}/docker/out/${initrd} ${root}/configs/debian-buster-amd64/initrds
mkdir -p ${root}/configs/debian-buster-amd64/signing && cp -v ${root}/keys/root.cert ${root}/configs/debian-buster-amd64/signing

echo "[INFO]: Create manifest.json for debian boot configuration"
touch ${root}/configs/debian-buster-amd64/manifest.json
sudo echo '{ 
  "version": 1, 
  "configs": [ 
    { 
      "name": "Debian Buster reproducible", 
      "kernel": "kernels/'$kernel'", 
      "kernel_args": "console=tty0 console=ttyS0,115200n8 rw rdinit=/lib/systemd/systemd", 
      "initramfs": "initrds/'$initrd'" 
    } 
  ], 
  "rootCert": "signing/root.cert" 
}' > ${root}/configs/debian-buster-amd64/manifest.json

cat ${root}/configs/debian-buster-amd64/manifest.json

echo "Successfully createt ${root}/configs/debian-buster-amd64/manifest.json"
