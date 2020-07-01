#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

kernel="${dir}/docker/out/debian-buster-amd64.vmlinuz"
kernel_backup="${kernel}.backup"
initramfs="${dir}/docker/out/debian-buster-amd64.cpio.gz"
initramfs_backup="${initramfs}.backup"
docker_image="debos"

if [ -f "${kernel}" ] && [ -f "${initramfs}" ]; then
    while true; do
       echo "Current Debian Buster:"
       ls -l "$(realpath --relative-to="${root}" "${kernel}")"
       ls -l "$(realpath --relative-to="${root}" "${initramfs}")"
       read -rp "Rebuild Debian Buster? (y/n)" yn
       case $yn in
          [Yy]* ) echo "[INFO]: backup existing files to $(realpath --relative-to="${root}" "$(dirname "${kernel}")")"; mv "${kernel}" "${kernel_backup}"; mv "${initramfs}" "${initramfs_backup}"; break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
       esac
    done 
fi


if docker image inspect debos > /dev/null 2> /dev/null; then
   echo "[INFO]: Using docker image"
   docker images ${docker_image}
else    
   echo "[INFO]: Build docker image for debos"
   echo ""
   docker build -t ${docker_image} "${dir}/docker"
fi

echo ""
echo "[INFO]: Build reproducible Debian Buster via debos in a docker container"
echo ""
docker run --env DEBOS_USER_ID=$(id -u) --env DEBOS_GROUP_ID=$(id -g) --cap-add=SYS_ADMIN -it -v "${root}:/system-transparency/:z" ${docker_image}

echo
echo "Debian kernel created at: $(realpath --relative-to="${root}" "${kernel}")"
echo "Debian initramfs created at: $(realpath --relative-to="${root}" "${initramfs}")"

